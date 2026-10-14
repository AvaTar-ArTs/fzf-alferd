# fzf-alfred v4 Finalization Plan

> **Status: complete (2026-10-14).** Tasks 1–8 are done; two departures from the
> plan as written are noted below. The code snippets below are the *original*
> sketches, kept for the record — the shipped code differs where noted.

## Completion record

| Task | Status | Notes |
|------|--------|-------|
| 1 — cache depth | ✅ | Superseded: the cache is now keyed by `search_path`/`excludes`/`max_results`, and scan depth is `max_results * 10`. |
| 2 — eza metadata | ✅ | Superseded: the awk column scan was replaced by a **fixed-position** parse (`-d --time-style=long-iso`) because filenames with spaces shifted the columns. |
| 3 — test suite | ✅ | Grew from 8 checks to **33** (JSON contract, `search_path` handling, cache/history, plist graph reachability, packaged artifact). |
| 4 — package `.alfredworkflow` | ✅ | Now reproducible via `scripts/build.sh` (Task 7 deviation) instead of an ad-hoc `zip`. |
| 5 — README | ✅ | Updated for two keywords, `jq`, the `v4/` layout and the build script. |
| 6 — Gallery metadata | ✅ | Updated for two keywords, `jq` and the real repo URL. |
| 7 — clean up old versions | ⚠️ **changed** | Old versions archived under `versions/v2` and `versions/v3` (there was never a committed v1). The "copy v4 to repo root" step was **dropped**: `v4/` stays canonical and the root holds only docs, the built artifact and `scripts/build.sh`. |
| 8 — final integration test | ✅ | `./v4/test.sh` (33/33) plus `./scripts/build.sh --check`; the packaged artifact is extracted and executed the way Alfred runs it. |

### Why Task 7 changed

Copying `v4/` into the repository root mixed the shippable workflow internals
(`info.plist`, `search.sh`, `lib.sh`) with repo metadata (`README.md`,
`CHANGELOG.md`, `docs/`, `versions/`), and duplicated `v4/`. Keeping `v4/`
canonical is consistent with `versions/v2`, `versions/v3`, makes diffs across
versions trivial, and lets `scripts/build.sh` be the single source of the
installable archive.

---

> **For the record:** the original plan text follows.

**Goal:** Finalize v4 as the ship version, package it, and prepare for Alfred Gallery submission.

**Architecture:** Pure zsh workflow using fd (file discovery), fzf (filtering), eza (metadata), with file-list caching, auto-update checks, search history, and standard Alfred modifier keys.

**Tech Stack:** zsh, fd, eza, fzf, Alfred 5

---

### Task 1: Fix v4 cache to include ~/github

**Objective:** Cache currently misses files in `~/github/` because fd only scans `$HOME` top-level. Fix to scan deeper.

**Files:**
- Modify: `v4/search.sh:95-100` (build_cache function)

**Step 1: Increase fd head limit**

Change `head -n $((max_results * 3))` to `head -n $((max_results * 10))` in build_cache.

**Step 2: Test**

Run: `./v4/search.sh "fzf" 2>&1 | head -5`
Expected: Returns results containing "fzf" from `~/github/fzf-alfred/`

**Step 3: Commit**

```bash
git add v4/search.sh
git commit -m "fix: increase fd scan depth for cache"
```

---

### Task 2: Fix v4 eza metadata parsing

**Objective:** eza metadata in subtitles shows `.rw-r--r--` instead of `-rw-r--r--` and is missing size/date.

**Files:**
- Modify: `v4/search.sh:56-66` (get_eza_metadata function)

**Step 1: Fix eza output parsing**

Replace the awk script with:

```bash
get_eza_metadata() {
    local file="$1"
    eza --icons=never --color=never --long --git \
        --time-style=relative "$file" 2>/dev/null | \
        awk '{
            perms=$1; size=$3;
            date=""; git="";
            for(i=4;i<=NF;i++) {
                if($i ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) { date=date" "$i; }
                else if($i ~ /^[0-9]{2}:[0-9]{2}$/) { date=date" "$i; }
                else if($i ~ /^[MADRCU?!]+$/ && date != "") { git=$i; }
            }
            gsub(/^ +| +$/,"",date);
            gsub(/^\./,"-",perms);
            printf "%s  %s  %s  %s", perms, size, date, git
        }'
}
```

**Step 2: Test**

Run: `./v4/search.sh "github" 2>&1 | head -3`
Expected: Subtitle shows `-rw-r--r--  1.2K  3h ago  M` format

**Step 3: Commit**

```bash
git add v4/search.sh
git commit -m "fix: correct eza metadata parsing in subtitles"
```

---

### Task 3: Add v4 test script

**Objective:** Create a test script that validates v4 functionality.

**Files:**
- Create: `v4/test.sh`

**Step 1: Write test script**

```bash
#!/bin/zsh
# v4 test suite

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:${PATH}"

PASS=0
FAIL=0

assert() {
    local desc="$1"
    local result="$2"
    if [[ -n "$result" ]]; then
        echo "PASS: $desc"
        ((PASS++))
    else
        echo "FAIL: $desc"
        ((FAIL++))
    fi
}

# Test 1: Basic search returns JSON
result=$(./v4/search.sh "README" 2>/dev/null | head -1)
assert "Basic search returns JSON" "$result"

# Test 2: Empty query returns eza listing
result=$(./v4/search.sh "" 2>/dev/null | head -1)
assert "Empty query returns results" "$result"

# Test 3: Results contain modifier keys
result=$(./v4/search.sh "github" 2>/dev/null | grep -o '"cmd"' | head -1)
assert "Results contain cmd modifier" "$result"

# Test 4: Results contain match property
result=$(./v4/search.sh "github" 2>/dev/null | grep -o '"match"' | head -1)
assert "Results contain match property" "$result"

# Test 5: Cache file is created
result=$(test -f "$HOME/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/avatararsts.fzf-alfred/file_list.cache" && echo "yes")
assert "Cache file exists" "$result"

# Test 6: History file is created
result=$(test -f "$HOME/Library/Application Support/Alfred/Workflow Data/avatararsts.fzf-alfred/history" && echo "yes")
assert "History file exists" "$result"

# Test 7: eza metadata in subtitle
result=$(./v4/search.sh "github" 2>/dev/null | grep -o 'rw-' | head -1)
assert "eza metadata in subtitle" "$result"

# Test 8: JSON is valid
result=$(./v4/search.sh "github" 2>/dev/null | head -1 | python3 -m json.tool > /dev/null 2>&1 && echo "yes")
assert "Output is valid JSON" "$result"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
```

**Step 2: Make executable**

Run: `chmod +x v4/test.sh`

**Step 3: Run tests**

Run: `./v4/test.sh`
Expected: All 8 tests pass

**Step 4: Commit**

```bash
git add v4/test.sh
git commit -m "test: add v4 test suite"
```

---

### Task 4: Package v4 as .alfredworkflow

**Objective:** Create installable `.alfredworkflow` file.

**Files:**
- Create: `fzf-alfred.alfredworkflow`

**Step 1: Create package**

Run: `cd v4 && zip -r ../fzf-alfred.alfredworkflow . -x "*.sh~" "test.sh"`
Expected: `fzf-alfred.alfredworkflow` created

**Step 2: Verify package**

Run: `unzip -l fzf-alfred.alfredworkflow`
Expected: Contains info.plist, search.sh, open.sh, dirinfo.sh

**Step 3: Commit**

```bash
git add fzf-alfred.alfredworkflow
git commit -m "build: package v4 as .alfredworkflow"
```

---

### Task 5: Update README for v4

**Objective:** Update README to reflect v4 as the ship version.

**Files:**
- Modify: `README.md`

**Step 1: Replace README content**

```markdown
# fzf-alfred

Alfred workflow with fd + eza + fzf for fuzzy file navigation.

## Features

- Fuzzy file search with fzf
- Rich file metadata with eza (icons, git status, permissions)
- Fast file discovery with fd
- File list caching (5min TTL)
- Auto-update via GitHub releases
- Search history
- Standard Alfred modifier keys

## Requirements

- Alfred 5 + Powerpack
- fd, eza, fzf (`brew install fd eza fzf`)

## Installation

1. Download `fzf-alfred.alfredworkflow`
2. Double-click to install

## Usage

- `fzfnav` + query — fuzzy search
- `Enter` — open file
- `Cmd+Enter` — reveal in Finder
- `Alt+Enter` — open in Terminal
- `Ctrl` — copy path
- `Cmd+L` — Large Type path

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `search_path` | `~` | Directory to search |
| `excludes` | `node_modules;.git;.cache;Library` | Exclude patterns |
| `max_results` | `100` | Max results |
| `cache_ttl` | `300` | Cache TTL (seconds) |

## License

MIT
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README for v4"
```

---

### Task 6: Create Alfred Gallery submission metadata

**Objective:** Prepare metadata for alfred.app submission.

**Files:**
- Create: `docs/alfred-gallery-submission.md`

**Step 1: Write submission doc**

```markdown
# Alfred Gallery Submission

## Workflow: fzf-alfred

**Name:** fzf-alfred
**Bundle ID:** avatararsts.fzf-alfred
**Category:** Productivity
**Tags:** file-handling, file-management, development, terminal

**Description:**
Fuzzy file navigation with fd + eza + fzf. Search files with fuzzy matching, view rich metadata (git status, permissions, size), and open with standard Alfred modifier keys.

**Features:**
- Fuzzy file search (fzf)
- Rich metadata (eza: git status, permissions, size, date)
- Fast file discovery (fd)
- File list caching
- Auto-update via GitHub releases
- Search history

**Keywords:** file, search, fuzzy, fzf, eza, fd, navigate, finder

**Screenshots:** [add before submission]

**Requirements:** Alfred 5+, fd, eza, fzf (brew install fd eza fzf)
```

**Step 2: Commit**

```bash
git add docs/alfred-gallery-submission.md
git commit -m "docs: add Alfred Gallery submission metadata"
```

---

### Task 7: Clean up old versions

**Objective:** Remove v1/v2/v3 scripts from root, keep only v4.

**Files:**
- Delete: `search.sh`, `open.sh`, `dirinfo.sh`, `info.plist`, `package.json`, `index.js`, `run-node.sh`

**Step 1: Move old versions to archive**

```bash
mkdir -p versions/v1 versions/v2 versions/v3
mv search.sh versions/v1/ 2>/dev/null
mv open.sh versions/v2/ 2>/dev/null
mv dirinfo.sh versions/v2/ 2>/dev/null
mv info.plist versions/v1/ 2>/dev/null
mv package.json versions/v3/ 2>/dev/null
mv index.js versions/v3/ 2>/dev/null
mv run-node.sh versions/v3/ 2>/dev/null
```

**Step 2: Copy v4 to root**

```bash
cp v4/info.plist ./info.plist
cp v4/search.sh ./search.sh
cp v4/open.sh ./open.sh
cp v4/dirinfo.sh ./dirinfo.sh
chmod +x search.sh open.sh dirinfo.sh
```

**Step 3: Commit**

```bash
git add -A
git commit -m "refactor: v4 as root, archive old versions"
```

---

### Task 8: Final integration test

**Objective:** Verify everything works from root.

**Step 1: Run tests**

Run: `./search.sh "README" | head -3`
Expected: Valid JSON with results

Run: `./search.sh "" | head -3`
Expected: Valid JSON with eza listing

**Step 2: Verify modifier keys in output**

Run: `./search.sh "github" | grep -o '"cmd"' | head -1`
Expected: `"cmd"`

**Step 3: Commit any fixes**

```bash
git add -A
git commit -m "test: final integration test" || echo "Nothing to commit"
```
