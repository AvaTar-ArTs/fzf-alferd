#!/bin/zsh
# fzf-alfred v4 — shared library for the Script Filters.
#
# Sourced by search.sh (everything) and dirs.sh (directories only). Keeping the
# config, cache and JSON emission in one place means both entry points produce
# byte-for-byte identical Alfred items.

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:${PATH}"

# --- Configuration (Alfred workflow variables override these defaults) ---
search_path="${search_path:-$HOME}"
max_results="${max_results:-100}"
excludes="${excludes:-node_modules;.git;.cache;Library}"
cache_ttl="${cache_ttl:-300}"                       # seconds
update_check_interval="${update_check_interval:-86400}"

# Alfred expands ~ in preferences, but be safe when invoked from a shell.
search_path="${search_path/#\~/$HOME}"

# --- Workflow directories ---
workflow_data="${alfred_workflow_data:-$HOME/Library/Application Support/Alfred/Workflow Data/avatararsts.fzf-alfred}"
workflow_cache="${alfred_workflow_cache:-$HOME/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/avatararsts.fzf-alfred}"
mkdir -p "$workflow_data" "$workflow_cache"

history_file="$workflow_data/history"
update_flag="$workflow_cache/.update_check"

# The cache is scoped to the variant and to the inputs that build it, so
# changing search_path, excludes or max_results never serves stale results.
# Usage: init_cache_key <variant>
init_cache_key() {
    local key
    key=$(printf '%s|%s|%s|%s' "$1" "$search_path" "$excludes" "$max_results" | shasum -a 256 | cut -c1-12)
    cache_file="$workflow_cache/file_list.$key.cache"
    cache_meta="$workflow_cache/file_list.$key.meta"
}

# --- Helpers ---------------------------------------------------------------

get_icon() {
    local file="$1"
    [[ -d "$file" ]] && { printf '📁'; return; }
    [[ -x "$file" ]] && { printf '⚡'; return; }
    case "${file##*.}" in
        py)             printf '🐍' ;;
        js|ts|jsx|tsx)  printf '📦' ;;
        md|markdown)    printf '📝' ;;
        json|yaml|yml|toml) printf '⚙️' ;;
        rs)             printf '🦀' ;;
        go)             printf '🐹' ;;
        sh|bash|zsh)    printf '🔧' ;;
        png|jpg|jpeg|gif|webp|svg) printf '🖼️' ;;
        mp3|wav|flac|m4a) printf '🎵' ;;
        mp4|mov|mkv|webm) printf '🎬' ;;
        zip|tar|gz|tgz|bz2|xz) printf '📦' ;;
        *)              printf '📄' ;;
    esac
}

# eza --long -d --git --time-style=long-iso renders a single line:
#   <perms> <size> <date> <time> [<gitstatus>] <name>
# long-iso dates are exactly two whitespace-free fields, so the columns before
# the name have FIXED positions — filenames containing spaces cannot shift them.
# -d makes eza describe a directory itself instead of listing its contents.
get_eza_metadata() {
    local file="$1"
    eza --icons=never --color=never --long --no-user --git -d --time-style=long-iso "$file" 2>/dev/null | awk '
        NR==1 {
            perms=$1; size=$2; date=$3 " " $4; git=""
            if ($5 ~ /^[-MADRCU?!]+$/) git=$5
            gsub(/^\./, "-", perms)          # macOS marks "no ACL" with '.'; show '-'
            printf "%s  %s  %s  %s", perms, size, date, git
        }'
}

# Emit one Alfred Script Filter item for a path, and record it in the history.
emit_item() {
    local file="$1"
    local icon basename rel_path meta match
    icon=$(get_icon "$file")
    basename=$(basename "$file")
    rel_path="${file/#$HOME/~}"
    meta=$(get_eza_metadata "$file")
    match="$basename $rel_path"

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
            text: { copy: $arg, largetype: $arg },
            variables: { action: "open" },
            mods: {
                cmd: { subtitle: "Reveal in Finder", arg: $arg, variables: { action: "reveal" } },
                alt: { subtitle: "Open in Terminal", arg: $arg, variables: { action: "terminal" } },
                ctrl: { subtitle: "Copy path", arg: $arg, variables: { action: "copy" } }
            }
        }'
}

# stdin: newline-separated paths -> a single Alfred JSON document.
emit_items() {
    while IFS= read -r file; do
        [[ -n "$file" ]] && emit_item "$file"
    done | jq -s '{ items: . }'
}

trim_history() {
    [[ -f "$history_file" ]] || return 0
    tail -n 100 "$history_file" > "$history_file.tmp" 2>/dev/null &&
        mv "$history_file.tmp" "$history_file"
}

# Record the query the user is typing (the design keeps the last 100 queries).
# Adjacent duplicate entries are skipped so a single search does not fill the
# file with identical lines.
record_query() {
    local q="$1"
    [[ -n "$q" ]] || return 0
    if [[ -f "$history_file" && "$(tail -n 1 "$history_file" 2>/dev/null)" == "$q" ]]; then
        return 0
    fi
    printf '%s\n' "$q" >> "$history_file"
    trim_history
}

# --- fd arguments -----------------------------------------------------------
build_fd_excludes() {
    fd_exclude_args=()
    local pattern
    for pattern in "${(@s:;:)excludes}"; do
        [[ -n "$pattern" ]] && fd_exclude_args+=(--exclude "$pattern")
    done
}

# --- Cache ------------------------------------------------------------------
# Usage: ensure_cache <files|dirs>
is_cache_valid() {
    [[ -f "$cache_file" && -f "$cache_meta" ]] || return 1
    local age=$(( $(date +%s) - $(stat -f %m "$cache_meta" 2>/dev/null || echo 0) ))
    (( age < cache_ttl ))
}

build_cache() {
    local type_args=()
    [[ "$1" == "dirs" ]] && type_args=(--type d)
    build_fd_excludes
    fd --hidden "${type_args[@]}" "${fd_exclude_args[@]}" . "$search_path" 2>/dev/null |
        head -n $(( max_results * 10 )) > "$cache_file"
    date +%s > "$cache_meta"
}

ensure_cache() {
    init_cache_key "$1"
    is_cache_valid || build_cache "$1"
}

# --- Auto-update check (only when actually running inside Alfred) ----------
check_for_updates() {
    [[ -n "$alfred_workflow_bundleid" || -n "$alfred_workflow_version" ]] || return 0
    [[ -f "$update_flag" ]] && (( $(date +%s) - $(cat "$update_flag" 2>/dev/null || echo 0) <= update_check_interval )) && return 0
    (
        latest=$(curl -fsSL https://api.github.com/repos/AvaTar-ArTs/fzf-alferd/releases/latest 2>/dev/null |
            sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
        current="${alfred_workflow_version:-0.0.0}"
        if [[ -n "$latest" && "$latest" != "$current" ]]; then
            osascript -e "display notification \"Update available: $latest (installed: $current)\" with title \"fzf-alfred\"" 2>/dev/null
        fi
        date +%s > "$update_flag"
    ) &
}

# --- Main flow shared by the filters ---------------------------------------
# Usage: run_filter <files|dirs>
run_filter() {
    local variant="$1"
    local query="${2:-}"

    ensure_cache "$variant"
    check_for_updates

    if [[ -z "$query" ]]; then
        # No query: list the immediate children of search_path.
        local type_args=()
        [[ "$variant" == "dirs" ]] && type_args=(--type d)
        build_fd_excludes
        fd --hidden --max-depth 1 "${type_args[@]}" "${fd_exclude_args[@]}" . "$search_path" 2>/dev/null |
            head -n "$max_results" |
            emit_items
    else
        local results
        results=$(fzf --filter "$query" --no-sort < "$cache_file" 2>/dev/null | head -n "$max_results")
        record_query "$query"
        if [[ -z "$results" ]]; then
            printf '{"items":[]}\n'
        else
            printf '%s\n' "$results" | emit_items
        fi
    fi
}
