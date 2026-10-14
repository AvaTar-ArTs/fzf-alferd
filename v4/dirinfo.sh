#!/bin/zsh
# fzf-alfred v4: Directory listing with eza formatting

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:${PATH}"

dir="${1:-.}"

eza --icons=always --color=always --long --git \
    --group-directories-first \
    --time-style=relative \
    --total-size \
    -I "node_modules|.git|.cache" \
    "$dir" 2>/dev/null
