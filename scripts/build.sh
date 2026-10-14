#!/bin/zsh
# Build fzf-alfred.alfredworkflow from the v4/ source directory.
#
# An .alfredworkflow file is just a zip whose ROOT contains info.plist and the
# scripts it references. Alfred installs the archive by unpacking it into
# Alfred.alfredpreferences/workflows/<uid>/.
#
# Usage: scripts/build.sh [--check]
#   --check  build to a temp file, verify it, then discard (used by CI/tests)

set -euo pipefail

repo_root="${0:A:h:h}"
src="$repo_root/v4"
artifact="$repo_root/fzf-alfred.alfredworkflow"

# Files that end up inside the archive, in a stable order.
files=(info.plist search.sh dirs.sh lib.sh icon.png)
runtime=(info.plist search.sh dirs.sh lib.sh)

for f in "${files[@]}"; do
    [[ -e "$src/$f" ]] || { echo "build: missing $src/$f" >&2; exit 1 }
done

if [[ "${1:-}" == "--check" ]]; then
    out="$(mktemp -t fzf-alfred.XXXXXX).alfredworkflow"
else
    out="$artifact"
fi

rm -f "$out"
( cd "$src" && zip -q -X "$out" "${files[@]}" )

# Verify: the archive must contain info.plist at its root and every runtime file.
unzip -Z1 "$out" > /dev/null
for f in "${runtime[@]}"; do
    unzip -Z1 "$out" | grep -qx "$f" || { echo "build: $f missing from archive" >&2; exit 1 }
done
plutil -lint "$src/info.plist" > /dev/null

if [[ "${1:-}" == "--check" ]]; then
    echo "build: OK ($out)"
    rm -f "$out"
else
    echo "build: wrote $out"
    unzip -l "$out"
fi
