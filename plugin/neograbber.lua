-- User commands for neograbber plugin
-- Provides convenient commands for controlling the server

-- Prevent loading plugin twice
if vim.g.loaded_neograbber then
  return
end
vim.g.loaded_neograbber = true

-- Create user commands
vim.api.nvim_create_user_command("NeograbberStart", function()
  require("neograbber").start()
end, {
  desc = "Start the neograbber server",
})

vim.api.nvim_create_user_command("NeograbberStop", function()
  require("neograbber").stop()
end, {
  desc = "Stop the neograbber server",
})

vim.api.nvim_create_user_command("NeograbberStatus", function()
  require("neograbber").status()
end, {
  desc = "Show neograbber server status",
})

vim.api.nvim_create_user_command("NeograbberRestart", function()
  require("neograbber").restart()
end, {
  desc = "Restart the neograbber server",
})
