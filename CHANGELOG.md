# Changelog

## 2026-10-14 — Session 1: Repository Setup & Research

### Steps

| # | Action | Tool Used | Result |
|---|--------|-----------|--------|
| 1 | Attempted `git remote add origin` to `ichoake/fzf-alferd.git` | `shell` | Failed — remote already existed with wrong URL |
| 2 | Checked existing remotes | `shell` (`git remote -v`) | Found `origin` pointing to `AvaTar-ArTs.github.io-.git` |
| 3 | Dispatched research subagent for Alfred + fzf + eza workflow patterns | `subagent` (general) | Completed — full architecture report with code snippets |
| 4 | Attempted `git remote set-url` + `git push` to `ichoake/fzf-alferd.git` | `shell` | Failed — 403 permission denied (AvaTar-ArTs ≠ ichoake) |
| 5 | User corrected target repo to `AvaTar-ArTs/fzf-alferd.git` | — | — |
| 6 | Attempted push to `AvaTar-ArTs/fzf-alferd.git` | `shell` | Failed — repo not found on GitHub |
| 7 | Checked git status | `shell` (`git status`) | Repo root was at `/Users/steven/github`, not `fzf-alfred/` |
| 8 | Listed `fzf-alfred/` directory | `shell` (`ls -la`) | Empty directory |
| 9 | Created `README.md` with project overview | `write` | Created |
| 10 | Initialized fresh git repo in `fzf-alfred/` | `shell` (`git init && git add && git commit`) | Initialized, 1 commit |
| 11 | Created GitHub repo and pushed | `shell` (`gh repo create --push`) | Pushed to `AvaTar-ArTs/fzf-alferd` |

### Tools Used

- `shell` — git commands, file listing, repo creation
- `write` — README.md creation
- `subagent` (general) — Alfred workflow research (fzf + eza + fd integration patterns)

### Research Summary

- **Architecture**: Script Filter → `fd` (file discovery) → `fzf --filter` (fuzzy match) → `eza` (metadata enrichment) → Alfred JSON output
- **Key references**: `yohasebe/fzf-alfred-workflow` (most complete), `mr-pennyworth/alfred-fzf` (simpler)
- **Gap identified**: No existing workflow combines fzf + eza — opportunity to build one
- **Next steps**: Implement `info.plist`, `search.sh`, and `dirinfo.sh` per research report

### Outcome

- Repository: https://github.com/AvaTar-ArTs/fzf-alferd
- Branch: `main`
- Status: Initialized with README, ready for workflow implementation

## 2026-10-14 — Session 2: v1 prototype and v2

### Steps

| # | Action | Tool Used | Result |
|---|--------|-----------|--------|
| 1 | Wrote a first pure-shell prototype (`search.sh` + `info.plist`, fd + fzf pipeline) | `write` | Worked, but never committed (no separate commit) |
| 2 | Extended it with standard Alfred modifier keys, Alfred-native result filtering and dynamic placeholders | `write` | Committed as `e60ea53` — this is **v2** |
| 3 | Added `open.sh` (modifier action handler) and `dirinfo.sh` (eza directory listing) | `write` | Committed with v2 |

### Outcome

- v2 = `info.plist`, `search.sh`, `open.sh`, `dirinfo.sh` at commit `e60ea53`.
- Known weakness: JSON was assembled by hand (`printf` + `json_escape`), which
  breaks on quotes and backslashes in filenames.
- v1 was a prototype only and was never committed; its ideas live on in v4.

## 2026-10-14 — Session 3: v3 (Node) and the v4 design

### Steps

| # | Action | Tool Used | Result |
|---|--------|-----------|--------|
| 1 | Built a Node.js Script Filter version (`index.js`, `package.json`, `run-node.sh`) | `write` | Committed as `088e398` — this is **v3** |
| 2 | Designed v4 as a runtime-free pure-shell rewrite | `write` | `docs/plans/2026-10-14-fzf-alfred-v4-design.md` |
| 3 | Built v4 (fd + fzf + eza, cache, history, auto-update, JSON via `jq`) | `write` | `v4/` in commit `088e398` |

### Outcome

- v3 requires a Node toolchain to be present, so a fresh install can fail silently.
- v4 needs only `fd`, `fzf`, `eza`, `jq`.

## 2026-10-14 — Session 4: v4 finalization, testing and packaging

### Steps

| # | Action | Tool Used | Result |
|---|--------|-----------|--------|
| 1 | Reviewed the Alfred reference workflows in `/Users/steven/Alfred-Backup/Alfred.alfredpreferences/workflows` | `shell` (`plutil`), `read` | Learned the real connection/conditional plist format and the script `type` enum (11 = zsh) |
| 2 | Found `info.plist` had **no connection from the Script Filter to anything** — modifier actions could never fire | `read` | Rewrote `connections` with a conditional chain (reveal → terminal → copy → open) |
| 3 | Found the empty-query branch emitted **invalid JSON** (newline-separated objects, no `items` wrapper) | `read` | Rewrote both branches to always emit one `{"items":[...]}` document |
| 4 | Fixed eza metadata parsing — filenames with spaces shifted the columns | `shell`, `edit` | Switched to fixed-position parse with `-d --time-style=long-iso` |
| 5 | Found the cache was global, so a changed `search_path` returned stale results | `edit` | Cache is now keyed by variant + `search_path` + `excludes` + `max_results` |
| 6 | Factored shared logic into `v4/lib.sh`; added `fzfdir` (directories-only) via `dirs.sh` | `write` | Two entry points, identical item shape |
| 7 | Rebuilt `info.plist` with two Script Filters and verified the whole graph | `write`, `shell` | `plutil -lint` passes; graph fully connected |
| 8 | Rewrote `test.sh` as a real suite (JSON contract, search_path handling, plist graph, packaged artifact) | `write` | **33 checks, 0 failures** |
| 9 | Added `scripts/build.sh` to package `v4/` into `fzf-alfred.alfredworkflow` | `write` | Builds and verifies the archive |
| 10 | Corrected the `versions/` archives (v2 files had been split across two dirs) | `shell`, `write` | `versions/v2` and `versions/v3` now match their commits exactly |
| 11 | Removed dead files (`open.sh`, `dirinfo.sh` — superseded by inline actions and `dirs.sh`) | `shell` | Cleaner repo root and workflow |

### Tools Used

- `shell` — `plutil`, `git ls-tree`/`git show`, `eza`/`fd` probes, `zip`/`unzip`, test runs
- `read` / `write` / `edit` — source, plist, docs and test changes
- Python (via `shell`) — plist graph validation (reachability, dangling connections)

### Fixes in this session

- **Workflow could not act on results** — the Script Filter was not connected to
  the modifier-action nodes. Now wired through a conditional chain.
- **Invalid JSON on empty query** — produced newline-separated objects instead of
  a single `{"items":[…]}` document.
- **Corrupted metadata for names containing spaces** — eza columns are now parsed
  from fixed positions.
- **Stale cache when changing the search path** — the cache is now path-scoped.
- **`versions/` archives were wrong** — v2's files had been split across
  `versions/v1` and `versions/v2`.

### Outcome

- 33/33 tests pass, including running the packaged `.alfredworkflow`.
- Shipping layout: `v4/` (source) → `scripts/build.sh` → `fzf-alfred.alfredworkflow`.
