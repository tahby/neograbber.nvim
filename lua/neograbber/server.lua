-- Socket server module for neograbber
-- Handles Unix socket or TCP connections to receive file open requests

local M = {}

-- Use vim.uv if available (Neovim 0.10+), otherwise fall back to vim.loop
local uv = vim.uv or vim.loop

-- Server state
local server = nil
local clients = {}

-- Configuration with defaults
M.config = {
  socket_path = nil, -- Will be set in setup()
  tcp_port = 9876,
  use_unix_socket = false,
}

-- Setup configuration
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Set default socket path if not provided
  if not M.config.socket_path then
    local runtime_dir = vim.fn.stdpath("run") or vim.fn.stdpath("cache")
    M.config.socket_path = runtime_dir .. "/neograbber.sock"
  end
end

-- Parse incoming JSON message
local function parse_message(data)
  local ok, result = pcall(vim.json.decode, data)
  if not ok then
    return nil, "Failed to parse JSON: " .. tostring(result)
  end
  return result, nil
end

-- Handle open action
local function handle_open(params)
  if not params.file then
    return false, "Missing file parameter"
  end

  -- Use vim.schedule to run in the main event loop
  vim.schedule(function()
    -- Open the file
    local ok, err = pcall(vim.cmd, "edit " .. vim.fn.fnameescape(params.file))
    if not ok then
      vim.notify("Neograbber: Failed to open file: " .. tostring(err), vim.log.levels.ERROR)
      return
    end

    -- Set cursor position if line/col provided
    if params.line then
      local line = tonumber(params.line) or 1
      local col = tonumber(params.col or 1)
      -- nvim_win_set_cursor uses 0-indexed columns
      pcall(vim.api.nvim_win_set_cursor, 0, {line, col - 1})
      -- Center the cursor line
      vim.cmd("normal! zz")
    end
  end)

  return true, nil
end

-- Handle incoming message
local function handle_message(data)
  local message, err = parse_message(data)
  if err then
    vim.notify("Neograbber: " .. err, vim.log.levels.WARN)
    return
  end

  if message.action == "open" then
    local ok, err_msg = handle_open(message)
    if not ok then
      vim.notify("Neograbber: " .. err_msg, vim.log.levels.ERROR)
    end
  else
    vim.notify("Neograbber: Unknown action: " .. tostring(message.action), vim.log.levels.WARN)
  end
end

local function send_http_response(client, status, body)
  local payload = body or '{"ok":true}'
  local status_line = status or "200 OK"
  local response = table.concat({
    "HTTP/1.1 " .. status_line,
    "Content-Type: application/json",
    "Content-Length: " .. #payload,
    "Connection: close",
    "",
    payload,
  }, "\r\n")

  client:write(response, function()
    if not client:is_closing() then
      client:close()
    end
  end)
end

local function try_handle_http(client, buffer)
  local header_end = buffer:find("\r\n\r\n", 1, true)
  if not header_end then
    return buffer, false
  end

  local header = buffer:sub(1, header_end - 1)
  local method, _path = header:match("^(%S+)%s+(%S+)%s+HTTP/%d%.%d")
  if not method then
    return buffer, false
  end

  local content_length = tonumber(header:match("\r\n[Cc]ontent%-[Ll]ength:%s*(%d+)")) or 0
  local body_start = header_end + 4
  if #buffer < body_start + content_length - 1 then
    return buffer, false
  end

  local body = ""
  if content_length > 0 then
    body = buffer:sub(body_start, body_start + content_length - 1)
  end

  if method == "POST" and body ~= "" then
    handle_message(body)
    send_http_response(client, "200 OK", '{"ok":true}')
  else
    send_http_response(client, "405 Method Not Allowed", '{"ok":false,"error":"Method Not Allowed"}')
  end

  return "", true
end

local function is_likely_json(buffer)
  local first_non_space = buffer:match("^%s*(%S)")
  return first_non_space == "{"
end

-- Handle client connection
local function on_connection(client)
  table.insert(clients, client)
  local buffer = ""

  -- Read data from client
  client:read_start(function(err, data)
    if err then
      vim.schedule(function()
        vim.notify("Neograbber: Read error: " .. tostring(err), vim.log.levels.ERROR)
      end)
      client:close()
      return
    end

    if data then
      buffer = buffer .. data

      if is_likely_json(buffer) then
        handle_message(buffer)
        buffer = ""
      else
        buffer = select(1, try_handle_http(client, buffer))
      end
    else
      -- Client disconnected
      client:close()
      -- Remove from clients table
      for i, c in ipairs(clients) do
        if c == client then
          table.remove(clients, i)
          break
        end
      end
    end
  end)
end

-- Start Unix socket server
local function start_unix_socket()
  -- Remove existing socket file if it exists
  if vim.fn.filereadable(M.config.socket_path) == 1 then
    vim.fn.delete(M.config.socket_path)
  end

  server = uv.new_pipe(false)

  server:bind(M.config.socket_path)
  server:listen(128, function(err)
    if err then
      vim.schedule(function()
        vim.notify("Neograbber: Listen error: " .. tostring(err), vim.log.levels.ERROR)
      end)
      return
    end

    local client = uv.new_pipe(false)
    server:accept(client)
    on_connection(client)
  end)

  vim.notify("Neograbber: Unix socket server started at " .. M.config.socket_path, vim.log.levels.INFO)
  return true
end

-- Start TCP server
local function start_tcp_server()
  server = uv.new_tcp()

  server:bind("127.0.0.1", M.config.tcp_port)
  server:listen(128, function(err)
    if err then
      vim.schedule(function()
        vim.notify("Neograbber: Listen error: " .. tostring(err), vim.log.levels.ERROR)
      end)
      return
    end

    local client = uv.new_tcp()
    server:accept(client)
    on_connection(client)
  end)

  vim.notify("Neograbber: HTTP server started on port " .. M.config.tcp_port, vim.log.levels.INFO)
  return true
end

-- Start the server
function M.start()
  if server then
    vim.notify("Neograbber: Server already running", vim.log.levels.WARN)
    return false
  end

  local ok, err = pcall(function()
    if M.config.use_unix_socket then
      return start_unix_socket()
    else
      return start_tcp_server()
    end
  end)

  if not ok then
    vim.notify("Neograbber: Failed to start server: " .. tostring(err), vim.log.levels.ERROR)
    server = nil
    return false
  end

  return true
end

-- Stop the server
function M.stop()
  if not server then
    vim.notify("Neograbber: Server not running", vim.log.levels.WARN)
    return false
  end

  -- Close all client connections
  for _, client in ipairs(clients) do
    if not client:is_closing() then
      client:close()
    end
  end
  clients = {}

  -- Close server
  if not server:is_closing() then
    server:close()
  end
  server = nil

  -- Remove Unix socket file if it exists
  if M.config.use_unix_socket and vim.fn.filereadable(M.config.socket_path) == 1 then
    vim.fn.delete(M.config.socket_path)
  end

  vim.notify("Neograbber: Server stopped", vim.log.levels.INFO)
  return true
end

-- Get server status
function M.status()
  if server then
    local msg
    if M.config.use_unix_socket then
      msg = "Server running (Unix socket: " .. M.config.socket_path .. ")"
    else
      msg = "Server running (TCP port: " .. M.config.tcp_port .. ")"
    end
    msg = msg .. " | Active connections: " .. #clients
    vim.notify("Neograbber: " .. msg, vim.log.levels.INFO)
    return true
  else
    vim.notify("Neograbber: Server not running", vim.log.levels.INFO)
    return false
  end
end

return M
