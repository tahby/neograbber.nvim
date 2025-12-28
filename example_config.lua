-- Example configuration for neograbber.nvim

require("neograbber").setup({
  socket_path = nil,
  tcp_port = 9876,
  use_unix_socket = false,
  auto_start = true,
})
