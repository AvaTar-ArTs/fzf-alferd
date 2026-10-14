# fzf-alfred

Alfred workflow for fuzzy file and folder navigation, combining **fd** (fast
discovery), **fzf** (fuzzy matching) and **eza** (rich metadata), driven entirely
by shell scripts — no Node.js, Python or PHP runtime needed.

## Features

- **`fzfnav`** — fuzzy search across files *and* directories
- **`fzfdir`** — fuzzy search across directories only (jump straight to a project folder)
- Rich metadata per result from eza: permissions, size, modified date and git status
- File-type icons (📁 folders, 🐍 Python, 📝 Markdown, …)
- Path-scoped file-list cache (5-minute TTL) so keystrokes stay instant after the first search
- Search history (`~/Library/Application Support/Alfred/Workflow Data/...`)
- Standard Alfred modifier actions on every result
- Background update check against GitHub releases
- Always emits valid JSON (built with `jq`, not hand-rolled escaping)

## Requirements

- Alfred 5 with the Powerpack
- `fd`, `fzf`, `eza` and `jq` on `PATH`:

  ```sh
  brew install fd fzf eza jq
  ```

## Installation

1. Download [`fzf-alfred.alfredworkflow`](https://github.com/AvaTar-ArTs/fzf-alferd/releases/latest/download/fzf-alfred.alfredworkflow)
   from the latest release.
2. Double-click it to install into Alfred.

Or build it yourself from source: `./scripts/build.sh`.

## Usage

Type a keyword, then a query:

| Keyword  | Searches                        |
|----------|---------------------------------|
| `fzfnav` | files and folders               |
| `fzfdir` | folders only                    |

Keys on a selected result:

| Key       | Action                                                     |
|-----------|------------------------------------------------------------|
| `Enter`   | Open the file (or folder) with the default application     |
| `⌘ Enter` | Reveal in Finder                                           |
| `⌥ Enter` | Open a Terminal (or iTerm) window in the item's folder     |
| `⌃ Enter` | Copy the full path to the clipboard                        |
| `⌘ L`     | Large Type (Alfred built-in)                               |
| `⌘ Y`     | Quick Look (Alfred built-in)                               |

## Configuration

Set these in the workflow's configuration sheet (Alfred preferences → Workflows →
fzf-alfred → `[𝔁]`):

| Variable     | Default                                | Description                                   |
|--------------|----------------------------------------|-----------------------------------------------|
| `search_path`| `~`                                    | Directory to search                           |
| `excludes`   | `node_modules;.git;.cache;Library`     | Semicolon-separated exclude patterns          |
| `max_results`| `100`                                  | Maximum number of results shown               |
| `cache_ttl`  | `300`                                  | Seconds before the cached file list is rebuilt |

## Repository layout

```
fzf-alfred/
├── v4/                          current source (canonical)
│   ├── info.plist               workflow definition
│   ├── lib.sh                   shared config, cache, eza metadata, JSON emission
│   ├── search.sh                fzfnav  — files + folders
│   ├── dirs.sh                  fzfdir  — folders only
│   ├── icon.png                 workflow icon
│   └── test.sh                  test suite
├── versions/                    earlier implementations (v2, v3), kept for comparison
├── scripts/build.sh             packages v4/ into the .alfredworkflow
├── docs/                        design notes, plans, gallery submission
└── fzf-alfred.alfredworkflow    built artifact (gitignored; shipped via Releases)
```

## Development

```sh
./v4/test.sh          # 36 checks: JSON contract, history, plist graph, packaged artifact
./scripts/build.sh    # rebuild fzf-alfred.alfredworkflow from v4/
```

An `.alfredworkflow` file is a zip whose root contains `info.plist` and the
scripts it references; `scripts/build.sh` produces it in that shape and verifies
the result. The archive is not committed — it is attached to each GitHub release
— because it embeds file timestamps and would otherwise churn on every rebuild.

## License

MIT
