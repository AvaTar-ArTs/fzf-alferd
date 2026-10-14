# fzf-alfred

Alfred workflow with fzf + eza for fuzzy file navigation.

## Features

- Fuzzy file search with Alfred's native filtering (with memorization)
- Rich file metadata with eza (icons, git status, permissions)
- Fast file discovery with fd
- Standard Alfred modifier key actions
- Dynamic placeholder support

## Requirements

- [Alfred 5](https://www.alfredapp.com/) with Powerpack
- [fzf](https://github.com/junegunn/fzf)
- [fd](https://github.com/sharkdp/fd)
- [eza](https://github.com/eza-community/eza)

```bash
brew install fzf fd eza
```

## Installation

1. Download the `.alfredworkflow` file from Releases
2. Double-click to install in Alfred
3. Configure search path in workflow settings

## Usage

- Keyword: `fzfnav` — fuzzy search files
- `Enter` — open file
- `Cmd+Enter` — reveal in Finder
- `Alt+Enter` — open in Terminal
- `Ctrl` — copy path to clipboard
- `Cmd+L` — show full path in Large Type

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `search_path` | `~` | Directory to search |
| `excludes` | `node_modules;.git;.cache;Library` | Exclude patterns (semicolon-separated) |
| `max_results` | `100` | Maximum results to show |

## v2 Changes

- Switched to Alfred's native filtering (enables result memorization/ranking)
- Standard Alfred modifier keys (matches Finder Crawl workflow)
- Added Ctrl (copy path) and Cmd+L (Large Type) actions
- Added `match` property to JSON output for better filtering
- Word matching mode for flexible search

## License

MIT
