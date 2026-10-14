#!/bin/zsh
# fzf-alfred v4 — Script Filter: fuzzy search across files AND directories.
#   keyword: fzfnav
#
# Pipeline: fd builds a cache -> fzf --filter narrows it -> eza enriches the
# subtitle. All shared logic lives in lib.sh.

source "${0:A:h}/lib.sh"
run_filter files "$1"
exit 0
