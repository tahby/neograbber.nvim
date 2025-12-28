-- Main neograbber module
-- Provides plugin initialization and public API

local M = {}

-- Import server module
local server = require("neograbber.server")

-- Default configuration
local defaults = {
  socket_path = nil, -- Will be set by server module if not provided
  tcp_port = 9876,
  use_unix_socket = false,
  auto_start = true,
}

-- Plugin configuration
M.config = {}

-- Setup function called by user in their config
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  -- Configure server module
  server.setup(M.config)

  -- Auto-start server if enabled
  if M.config.auto_start then
    server.start()
  end
end

-- Export server functions for direct access
M.start = function()
  return server.start()
end

M.stop = function()
  return server.stop()
end

M.status = function()
  return server.status()
end

M.restart = function()
  if server.stop() then
    -- Small delay before restarting
    vim.defer_fn(function()
      server.start()
    end, 100)
    return true
  end
  return false
end

return M
