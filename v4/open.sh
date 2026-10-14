#!/bin/zsh
# fzf-alfred v4: Action handler with standard Alfred modifier keys

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:${PATH}"

file="${1:-}"
action="${action:-open}"

case "$action" in
    reveal)
        open -R "$file"
        ;;
    terminal)
        if command -v iTerm &>/dev/null; then
            osascript -e "tell application \"iTerm\" to create window with default profile command \"cd '$file'\""
        else
            osascript -e "tell application \"Terminal\" to do script \"cd '$file'\""
        fi
        ;;
    copy)
        echo -n "$file" | pbcopy
        ;;
    large)
        echo "$file"
        ;;
    *)
        open "$file"
        ;;
esac
