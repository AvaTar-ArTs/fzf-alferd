#!/bin/bash
# Alfy run-node.sh - finds the Node.js binary for Alfred workflows
# From: https://github.com/sindresorhus/alfy

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:${PATH}"

# Try to find node in common locations
if command -v node &>/dev/null; then
    exec node "$@"
fi

# Check fnm
if [ -d "$HOME/.fnm" ]; then
    eval "$(fnm env)" 2>/dev/null
    exec node "$@"
fi

# Check nvm
if [ -d "$HOME/.nvm" ]; then
    [ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"
    exec node "$@"
fi

# Check Homebrew
if [ -f "/opt/homebrew/bin/node" ]; then
    exec /opt/homebrew/bin/node "$@"
fi

if [ -f "/usr/local/bin/node" ]; then
    exec /usr/local/bin/node "$@"
fi

echo "Error: node not found. Please install Node.js 18+" >&2
exit 1
