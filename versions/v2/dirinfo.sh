#!/bin/zsh
# List directory contents with eza formatting
# Used by Folder Action or Browse in Alfred

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:${PATH}"

dir="${1:-.}"

# Output eza-formatted listing as Alfred JSON items
eza --icons=always --color=always --long --git \
    --group-directories-first \
    --time-style=relative \
    --total-size \
    -I "node_modules|.git|.cache" \
    "$dir" 2>/dev/null | \
while IFS= read -r line; do
    # Parse eza long output to build structured items
    # Format: perms links size user group date time git name
    echo "$line"
done
