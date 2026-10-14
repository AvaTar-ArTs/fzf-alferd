#!/bin/zsh
# fzf + eza powered file navigation for Alfred
# v2: Alfred native filtering + standard modifier keys + dynamic placeholders
# Called by Alfred Script Filter with "{query}"

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:${PATH}"

# --- Configuration (from Alfred variables) ---
search_path="${search_path:-$HOME}"
max_results="${max_results:-100}"
excludes="${excludes:-node_modules;.git;.cache;Library}"

# Build fd exclude args
fd_args=()
IFS=';' read -ra exclude_arr <<< "$excludes"
for pattern in "${exclude_arr[@]}"; do
    [[ -n "$pattern" ]] && fd_args+=(--exclude "$pattern")
done

# --- Generate candidates with fd ---
# v2: Return all results, let Alfred handle filtering (alfredfiltersresults: true)
# This enables Alfred's memorization (ranking based on past usage)
# matchmode 2 = "Word matching - Any order" for flexible search
query="${1:-}"

if [[ -z "$query" ]]; then
    # No query: show top-level directories with eza
    eza --icons=always --color=always --group-directories-first \
        --time-style=relative --git "$search_path" 2>/dev/null | \
    while IFS= read -r line; do
        echo "{\"title\": \"$line\", \"arg\": \"$search_path\", \"match\": \"$search_path\"}"
    done | head -n "$max_results"
else
    # With query: fd generates candidates, Alfred filters
    fd --hidden "${fd_args[@]}" . "$search_path" 2>/dev/null | \
        head -n "$max_results" | \
        while IFS= read -r file; do
            # Get eza metadata for subtitle
            meta=$(eza --icons=never --color=never --long --git \
                   --time-style=relative "$file" 2>/dev/null | \
                   awk '{print $1, $3, $4, $5}')
            # Determine icon based on file type
            if [[ -d "$file" ]]; then
                icon="📁"
            elif [[ -x "$file" ]]; then
                icon="⚡"
            else
                icon="📄"
            fi
            # Escape for JSON
            title=$(basename "$file")
            rel_path="${file/#$HOME/~}"
            # v2: Add match property for Alfred's filtering
            match="$title $rel_path"
            echo "{\"uid\":\"$file\",\"title\":\"$icon $title\",\"subtitle\":\"$rel_path  $meta\",\"arg\":\"$file\",\"type\":\"file\",\"match\":\"$match\"}"
        done
fi
