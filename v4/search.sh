#!/bin/zsh
# fzf-alfred v4: Pure shell workflow with all best practices incorporated
# - fd + fzf pipeline (from v1)
# - Standard Alfred modifier keys (from v2)
# - Proper JSON generation (fix v1/v2 escaping issues)
# - Caching with expiry (from alfy concept)
# - Auto-update check (from OneUpdater concept)
# - Search history (from yohasebe/fzf-alfred-workflow)
# - eza metadata enrichment

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:${PATH}"

# --- Configuration ---
search_path="${search_path:-$HOME}"
max_results="${max_results:-100}"
excludes="${excludes:-node_modules;.git;.cache;Library}"
cache_ttl="${cache_ttl:-300}"  # 5 minutes
update_check_interval="${update_check_interval:-86400}"  # 24 hours

# --- Workflow directories ---
workflow_dir="${alfred_workflow_data:-$HOME/Library/Application Support/Alfred/Workflow Data/avatararsts.fzf-alfred}"
cache_dir="${alfred_workflow_cache:-$HOME/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/avatararsts.fzf-alfred}"
mkdir -p "$workflow_dir" "$cache_dir"

# --- Helpers ---
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

get_icon() {
    local file="$1"
    if [[ -d "$file" ]]; then
        printf '📁'
    elif [[ -x "$file" ]]; then
        printf '⚡'
    else
        local ext="${file##*.}"
        case "$ext" in
            py) printf '🐍' ;;
            js|ts|jsx|tsx) printf '📦' ;;
            md) printf '📝' ;;
            json|yaml|yml|toml) printf '⚙️' ;;
            rs) printf '🦀' ;;
            go) printf '🐹' ;;
            sh|bash|zsh) printf '🔧' ;;
            *) printf '📄' ;;
        esac
    fi
}

get_eza_metadata() {
    local file="$1"
    eza --icons=never --color=never --long --git \
        --time-style=relative "$file" 2>/dev/null | \
        awk '{
            perms=$1; size=$3;
            date=""; git="";
            for(i=4;i<=NF;i++) {
                if($i ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) { date=date" "$i; }
                else if($i ~ /^[0-9]{2}:[0-9]{2}$/) { date=date" "$i; }
                else if($i ~ /^[MADRCU?!]+$/ && date != "") { git=$i; }
            }
            gsub(/^ +| +$/,"",date);
            gsub(/^\./,"-",perms);
            printf "%s  %s  %s  %s", perms, size, date, git
        }'
}

# --- Caching ---
cache_file="$cache_dir/file_list.cache"
cache_meta="$cache_dir/file_list.meta"

is_cache_valid() {
    [[ -f "$cache_file" && -f "$cache_meta" ]] || return 1
    local now=$(date +%s)
    local mtime=$(stat -f %m "$cache_meta" 2>/dev/null || echo 0)
    local age=$((now - mtime))
    [[ $age -lt $cache_ttl ]]
}

build_cache() {
    local fd_args=()
    local exclude_arr=("${(s:;:)excludes}")
    for pattern in "${exclude_arr[@]}"; do
        [[ -n "$pattern" ]] && fd_args+=(--exclude "$pattern")
    done

    fd --hidden "${fd_args[@]}" . "$search_path" 2>/dev/null | \
        head -n $((max_results * 10)) > "$cache_file"
    date +%s > "$cache_meta"
}

if ! is_cache_valid; then
    build_cache
fi

# --- Auto-update check ---
update_flag="$cache_dir/.update_check"
if [[ ! -f "$update_flag" ]] || [[ $(($(date +%s) - $(cat "$update_flag" 2>/dev/null || echo 0))) -gt $update_check_interval ]]; then
    (
        local latest=$(curl -s https://api.github.com/repos/AvaTar-ArTs/fzf-alferd/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
        local current=$(cat "${alfred_workflow_version:-$workflow_dir/version}" 2>/dev/null || echo "0.0.0")
        if [[ -n "$latest" && "$latest" != "$current" ]]; then
            osascript -e "display notification \"Update available: $latest\" with title \"fzf-alfred\""
        fi
        date +%s > "$update_flag"
    ) &
fi

# --- Search history ---
history_file="$workflow_dir/history"
touch "$history_file"

# --- Main ---
query="${1:-}"

if [[ -z "$query" ]]; then
    # No query: show top-level directories with eza
    eza --icons=always --color=always --group-directories-first \
        --time-style=relative --git "$search_path" 2>/dev/null | \
    while IFS= read -r line; do
        local title=$(json_escape "$line")
        local arg=$(json_escape "$search_path")
        printf '{"title":"%s","arg":"%s","match":"%s"}\n' "$title" "$arg" "$search_path"
    done | head -n "$max_results"
else
    # With query: fzf --filter on cached results
    local results=$(fzf --filter "$query" --no-sort < "$cache_file" 2>/dev/null | head -n "$max_results" || true)

    if [[ -z "$results" ]]; then
        printf '{"items":[]}\n'
        return 0
    fi

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        local icon=$(get_icon "$file")
        local basename=$(basename "$file")
        local rel_path="${file/#$HOME/~}"
        local meta=$(get_eza_metadata "$file")
        local match="$basename $rel_path"

        # Save to history
        echo "$file" >> "$history_file"
        # Keep only last 100 entries
        tail -n 100 "$history_file" > "$history_file.tmp" && mv "$history_file.tmp" "$history_file"

        jq -cn \
            --arg uid "$file" \
            --arg title "$icon $basename" \
            --arg subtitle "$rel_path  $meta" \
            --arg arg "$file" \
            --arg match "$match" \
            '{
                uid: $uid,
                title: $title,
                subtitle: $subtitle,
                arg: $arg,
                type: "file",
                match: $match,
                mods: {
                    cmd: { subtitle: "Reveal in Finder", arg: $arg, variables: { action: "reveal" } },
                    alt: { subtitle: "Open in Terminal", arg: $arg, variables: { action: "terminal" } },
                    ctrl: { subtitle: "Copy path", arg: $arg, variables: { action: "copy" } }
                }
            }'
    done <<< "$results"
fi
