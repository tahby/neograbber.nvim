-- Example configuration for neograbber.nvim
-- Copy this to your Neovim config and adjust as needed

-- Basic setup (recommended)
require("neograbber").setup()

-- Custom configuration examples:

-- Example 1: Use Unix socket instead of HTTP
-- require("neograbber").setup({
--   use_unix_socket = true,
--   socket_path = "/tmp/neograbber.sock",
-- })

-- Example 2: Custom socket path
-- require("neograbber").setup({
--   socket_path = "/tmp/my-neograbber.sock",
-- })

-- Example 3: Manual start (don't auto-start)
-- require("neograbber").setup({
--   auto_start = false,
-- })
-- -- Then start manually when needed:
-- -- :NeograbberStart

-- Example 4: Full custom configuration
-- require("neograbber").setup({
--   socket_path = vim.fn.expand("~/.config/nvim/neograbber.sock"),
--   tcp_port = 8888,
--   use_unix_socket = true,
--   auto_start = true,
-- })

-- Using the Lua API directly:
-- local neograbber = require("neograbber")
-- neograbber.setup()
-- neograbber.start()
-- neograbber.status()
-- neograbber.stop()
-- neograbber.restart()

-- Keybindings (optional):
-- vim.keymap.set("n", "<leader>ns", function() require("neograbber").status() end,
--   { desc = "Neograbber status" })
-- vim.keymap.set("n", "<leader>nr", function() require("neograbber").restart() end,
--   { desc = "Neograbber restart" })
