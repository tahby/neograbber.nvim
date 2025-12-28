# neograbber.nvim

A Neovim plugin that provides a socket server for receiving file navigation commands from external applications.

## Features

- Local HTTP endpoint for opening files with line/column positioning
- Optional Unix socket for raw JSON messages
- Automatic server startup on plugin load
- User commands for server management
- Asynchronous message handling using vim.uv/vim.loop

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "neograbber.nvim",
  config = function()
    require("neograbber").setup({
      -- Optional configuration
      use_unix_socket = false, -- Use Unix socket (default: false)
      tcp_port = 9876,         -- TCP port if not using Unix socket (default: 9876)
      auto_start = true,       -- Auto-start server on load (default: true)
      socket_path = nil,       -- Custom socket path (default: stdpath("run")/neograbber.sock)
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "neograbber.nvim",
  config = function()
    require("neograbber").setup()
  end,
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'neograbber.nvim'
```

Then in your `init.lua`:

```lua
require("neograbber").setup()
```

## Configuration

Default configuration:

```lua
{
  socket_path = nil,           -- Auto-detected: stdpath("run")/neograbber.sock
  tcp_port = 9876,             -- Port for TCP mode
  use_unix_socket = false,     -- Use Unix socket instead of HTTP
  auto_start = true,           -- Start server automatically
}
```

## Usage

### User Commands

- `:NeograbberStart` - Start the server
- `:NeograbberStop` - Stop the server
- `:NeograbberStatus` - Show server status
- `:NeograbberRestart` - Restart the server

### Lua API

```lua
local neograbber = require("neograbber")

-- Start server
neograbber.start()

-- Stop server
neograbber.stop()

-- Check status
neograbber.status()

-- Restart server
neograbber.restart()
```

## Protocol

The plugin accepts JSON messages with the following format:

```json
{
  "action": "open",
  "file": "/path/to/file.txt",
  "line": 42,
  "col": 10
}
```

Fields:
- `action` (required): Currently only "open" is supported
- `file` (required): Absolute or relative path to the file
- `line` (optional): Line number (1-indexed)
- `col` (optional): Column number (1-indexed)

### Example: Sending a message via HTTP

```bash
curl -X POST http://127.0.0.1:9876/open \
  -H "Content-Type: application/json" \
  -d '{"action":"open","file":"/tmp/test.txt","line":10,"col":5}'
```

### Example: Sending a message via Unix socket

Enable `use_unix_socket = true` first, then send a message:

```bash
echo '{"action":"open","file":"/tmp/test.txt","line":10,"col":5}' | nc -U /path/to/neograbber.sock
```

## How It Works

1. The plugin starts a local HTTP server (or Unix socket when enabled)
2. External applications send JSON messages
3. Messages are parsed and executed asynchronously
4. Files are opened with the specified cursor position
5. The view is centered on the cursor line

## Troubleshooting

### Server won't start

- Check if the socket path is accessible
- Verify no other process is using the socket/port
- Run `:NeograbberStatus` to check current state

### Socket file not found

This only applies when `use_unix_socket = true`. The default socket path is `vim.fn.stdpath("run") .. "/neograbber.sock"`. To find your socket path:

```lua
:lua print(vim.fn.stdpath("run") .. "/neograbber.sock")
```

Or configure a custom path:

```lua
require("neograbber").setup({
  socket_path = "/tmp/neograbber.sock"
})
```

### Messages not being received

- Ensure the server is running (`:NeograbberStatus`)
- Verify the JSON message format is correct
- Check Neovim messages (`:messages`) for errors

## License

MIT
