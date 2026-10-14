# fzf-alfred

Alfred workflow with fzf + eza for fuzzy file navigation.

## Features

- Fuzzy file search with fzf
- Rich file metadata with eza (icons, git status, permissions)
- Fast file discovery with fd
- Modifier key actions (Cmd+Enter → Terminal, Alt+Enter → Finder)

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
- `Cmd+Enter` — open in Terminal
- `Alt+Enter` — reveal in Finder

## License

MIT
