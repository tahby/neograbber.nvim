# neograbber.nvim

Neovim listener for open-file requests from the Chrome extension.

## Install

Add `neograbber.nvim` to your runtimepath or plugin manager, then:

```lua
require("neograbber").setup()
```

## Configuration

Defaults:

```lua
{
  socket_path = nil,
  tcp_port = 9876,
  use_unix_socket = false,
  auto_start = true,
}
```

## Commands

- `:NeograbberStart`
- `:NeograbberStop`
- `:NeograbberStatus`
- `:NeograbberRestart`

## Protocol

HTTP `POST http://127.0.0.1:9876/open`:

```json
{"action":"open","file":"/path/to/file","line":42,"col":8}
```

## Test

```bash
nvim --headless "+luafile neograbber.nvim/test_plugin.lua" +qall
./neograbber.nvim/test_message.sh /abs/path 42 8
```
