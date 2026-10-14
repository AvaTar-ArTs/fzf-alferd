# Alfred Gallery Submission

## Workflow: fzf-alfred

**Name:** fzf-alfred
**Bundle ID:** avatararsts.fzf-alfred
**Category:** Productivity
**Tags:** file-handling, file-management, development, terminal
**Repository:** https://github.com/AvaTar-ArTs/fzf-alferd

**Description:**
Fuzzy file and folder navigation with fd + fzf + eza. Search files or folders
across your chosen directory, see rich metadata (permissions, size, modified
date, git status) in the subtitle, and act on results with standard Alfred
modifier keys. Pure shell — no Node/Python/PHP runtime required.

**Features:**
- Two keywords: `fzfnav` (files + folders) and `fzfdir` (folders only)
- Rich metadata per result (eza: permissions, size, date, git status)
- Fast file discovery (fd) with a path-scoped result cache
- File-type icons
- Search history
- Auto-update check against GitHub releases
- Always-valid JSON output (built with jq)

**Keywords:** file, folder, directory, search, fuzzy, fzf, eza, fd, navigate, finder

**Requirements:** Alfred 5+ with Powerpack, plus `fd`, `fzf`, `eza` and `jq`
(`brew install fd fzf eza jq`).

**Install:** download `fzf-alfred.alfredworkflow` and double-click.

**Configuration:** `search_path`, `excludes`, `max_results`, `cache_ttl`
(editable from the workflow's configuration sheet).

**Notes for reviewers:**
- The workflow calls the four required tools from `PATH`; it prepends
  `/opt/homebrew/bin`, `/usr/local/bin` and `/opt/local/bin` so a standard
  Homebrew/MacPorts install is found without further setup.
- The `.alfredworkflow` is built by `scripts/build.sh` from `v4/`; the archive
  root contains `info.plist` and the referenced scripts.
