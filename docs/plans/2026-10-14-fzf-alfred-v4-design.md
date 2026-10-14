# fzf-alfred v4 Design Doc

## Goal
Ship a pure-shell Alfred workflow with fd + eza + fzf that includes caching, auto-update, search history, and standard Alfred modifier keys.

## Approved Approach
v4 (Pure Shell) — no Node.js dependency, works immediately after `.alfredworkflow` install.

## Architecture

```
User types: fzfnav <query>
        │
        ▼
┌─ search.sh ─────────────────────────────────────────┐
│ 1. Check cache (5min TTL)                           │
│ 2. If stale: rebuild with fd                        │
│ 3. Filter with fzf --filter                         │
│ 4. Enrich with eza metadata                         │
│ 5. Output Alfred JSON with modifier keys            │
└──────────────────────────────────────────────────────┘
        │
        ▼
┌─ Alfred Dropdown ───────────────────────────────────┐
│ Enter: Open file                                    │
│ Cmd+Enter: Reveal in Finder                         │
│ Alt+Enter: Open in Terminal                         │
│ Ctrl: Copy path                                     │
│ Cmd+L: Large Type                                   │
└──────────────────────────────────────────────────────┘
```

## Components

| Component | File | Purpose |
|-----------|------|---------|
| Script Filter | `v4/search.sh` | Main search logic |
| Action Handler | `v4/open.sh` | Route modifier key actions |
| Directory Info | `v4/dirinfo.sh` | eza-formatted listings |
| Workflow Def | `v4/info.plist` | Alfred workflow definition |

## Features

- **Caching**: File list cached for 5 minutes (configurable via `cache_ttl`)
- **Auto-update**: Checks GitHub releases every 24h, shows notification
- **Search history**: Last 100 queries stored
- **Standard modifier keys**: Matches Alfred conventions
- **eza metadata**: Git status, permissions, size, date
- **Extension-aware icons**: 🐍 py, 📦 js/ts, 📝 md, ⚙️ json/yaml, etc.

## Constraints

- Pure shell (zsh) — no Node.js, no Python
- Dependencies: fd, eza (installed via Homebrew)
- Alfred 5 + Powerpack required
- macOS only

## Distribution

1. Package as `.alfredworkflow` (zip with info.plist at root)
2. Submit to Alfred Gallery (alfred.app)
3. Auto-update via GitHub releases

## Verification

- [ ] Search returns results
- [ ] Modifier keys work (Enter/Cmd/Alt/Ctrl/Cmd+L)
- [ ] Cache builds and expires
- [ ] Auto-update check runs
- [ ] History is saved
- [ ] eza metadata appears in subtitles
- [ ] Exclude patterns work
