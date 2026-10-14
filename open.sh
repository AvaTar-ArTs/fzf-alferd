#!/bin/zsh
# File/directory action handler
# v2: Routes based on action variable from Alfred
# Standard Alfred modifier key mapping

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:${PATH}"

file="${1:-}"
action="${action:-open}"

case "$action" in
    reveal)
        # Reveal in Finder
        open -R "$file"
        ;;
    terminal)
        # Open in Terminal (iTerm2 if available, else Terminal.app)
        if command -v iTerm &>/dev/null; then
            osascript -e "tell application \"iTerm\" to create window with default profile command \"cd '$file'\""
        else
            osascript -e "tell application \"Terminal\" to do script \"cd '$file'\""
        fi
        ;;
    copy)
        # Copy path to clipboard
        echo -n "$file" | pbcopy
        ;;
    large)
        # Large Type (handled by Alfred output object, this is fallback)
        echo "$file"
        ;;
    *)
        # Default: open with default application
        open "$file"
        ;;
esac
