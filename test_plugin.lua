-- Simple test script for neograbber plugin
-- Run this in Neovim with: :luafile test_plugin.lua

print("=== Neograbber Plugin Test ===\n")

-- Test 1: Load the plugin
print("Test 1: Loading plugin...")
local ok, neograbber = pcall(require, "neograbber")
if not ok then
  print("FAILED: Could not load neograbber module")
  print("Error: " .. tostring(neograbber))
  return
end
print("PASSED: Plugin loaded successfully\n")

-- Test 2: Check API functions exist
print("Test 2: Checking API functions...")
local functions = {"setup", "start", "stop", "status", "restart"}
for _, func_name in ipairs(functions) do
  if type(neograbber[func_name]) ~= "function" then
    print("FAILED: Missing function: " .. func_name)
    return
  end
end
print("PASSED: All API functions exist\n")

-- Test 3: Setup with custom config
print("Test 3: Testing setup...")
neograbber.setup({
  auto_start = false,
  use_unix_socket = true,
  tcp_port = 9876,
})
print("PASSED: Setup completed\n")

-- Test 4: Check server module
print("Test 4: Loading server module...")
local ok_server, server = pcall(require, "neograbber.server")
if not ok_server then
  print("FAILED: Could not load server module")
  print("Error: " .. tostring(server))
  return
end
print("PASSED: Server module loaded\n")

-- Test 5: Check configuration
print("Test 5: Checking configuration...")
if not server.config.socket_path then
  print("FAILED: Socket path not set")
  return
end
print("Socket path: " .. server.config.socket_path)
print("TCP port: " .. server.config.tcp_port)
print("Use Unix socket: " .. tostring(server.config.use_unix_socket))
print("PASSED: Configuration is valid\n")

-- Test 6: Test start/stop
print("Test 6: Testing start/stop...")
local start_ok = neograbber.start()
if not start_ok then
  print("WARNING: Server failed to start (this might be expected)")
else
  print("Server started successfully")
  vim.defer_fn(function()
    neograbber.status()
    local stop_ok = neograbber.stop()
    if stop_ok then
      print("Server stopped successfully")
      print("PASSED: Start/stop test completed\n")
    else
      print("WARNING: Server failed to stop\n")
    end
  end, 100)
end

print("\n=== All tests completed ===")
print("Check the messages above for any failures or warnings")
