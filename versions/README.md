# Archived versions

Earlier implementations, kept for reference and A/B comparison. They are **not**
installed or built — only `v4/` is the shipping workflow.

| Version | Files | Approach | Why it was superseded |
|---------|-------|----------|-----------------------|
| `v1` | *(never committed)* | fd + fzf pipeline in a single `search.sh` | Prototype only; folded into v4. No committed artifact exists. |
| `v2` | `info.plist`, `search.sh`, `open.sh`, `dirinfo.sh` | Standard Alfred modifier keys, Alfred-native result filtering, dynamic placeholders | Hand-rolled JSON escaping broke on quotes/backslashes; no caching. |
| `v3` | `index.js`, `package.json`, `run-node.sh` | Node.js Script Filter | Required a Node runtime/toolchain to be present, so a fresh install could fail silently. |
| `v4` | see `../v4/` | Pure shell (zsh) + `jq`, shared `lib.sh`, fd + fzf + eza, path-scoped cache, search history | **Current.** No runtime beyond `fd`, `fzf`, `eza`, `jq`. |

### Notes

- `v2` corresponds to commit `e60ea53`.
- `v3` corresponds to commit `088e398`.
- `v1` predates the first workflow commit (`1d9edac` was docs only), so there is
  nothing to archive for it — the fd + fzf idea it introduced lives on in
  `v4/lib.sh`.
