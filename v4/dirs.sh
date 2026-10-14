#!/bin/zsh
# fzf-alfred v4 — Script Filter: fuzzy search across directories only.
#   keyword: fzfdir
#
# Useful for jumping straight to a project folder. Directory metadata comes
# from eza (via lib.sh), so a folder shows its own size/date, not its contents.

source "${0:A:h}/lib.sh"
run_filter dirs "$1"
exit 0
