#!/bin/bash
# Test script to send messages to neograbber

# Default socket path (adjust if needed)
# Note: Requires use_unix_socket = true in Neograbber config.
SOCKET_PATH="${XDG_RUNTIME_DIR:-/tmp}/neograbber.sock"

# Check if socket exists
if [ ! -S "$SOCKET_PATH" ]; then
  echo "Error: Socket not found at $SOCKET_PATH"
  echo "Make sure neograbber is running in Neovim"
  echo "You can find the socket path by running in Neovim:"
  echo "  :lua print(vim.fn.stdpath('run') .. '/neograbber.sock')"
  exit 1
fi

# Parse arguments
FILE="${1:-}"
LINE="${2:-1}"
COL="${3:-1}"

if [ -z "$FILE" ]; then
  echo "Usage: $0 <file> [line] [col]"
  echo ""
  echo "Examples:"
  echo "  $0 /tmp/test.txt"
  echo "  $0 /tmp/test.txt 10"
  echo "  $0 /tmp/test.txt 10 5"
  exit 1
fi

# Build JSON message
JSON=$(cat <<EOF
{"action":"open","file":"$FILE","line":$LINE,"col":$COL}
EOF
)

# Send to socket
echo "$JSON" | nc -U "$SOCKET_PATH"

if [ $? -eq 0 ]; then
  echo "Message sent successfully"
else
  echo "Failed to send message"
  exit 1
fi
