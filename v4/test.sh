#!/bin/zsh
# fzf-alfred v4 test suite
#
# Verifies the two things that actually break Alfred workflows:
#   1. search.sh always emits ONE valid JSON object with an "items" array
#   2. info.plist is a valid plist whose connections point at real nodes

export PATH="/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:${PATH}"

cd "${0:A:h}/.."   # repo root, regardless of where the test is invoked from

PASS=0
FAIL=0

assert() {
    local desc="$1" result="$2"
    if [[ -n "$result" ]]; then
        echo "  PASS: $desc"
        ((PASS++))
    else
        echo "  FAIL: $desc"
        ((FAIL++))
    fi
}

json_ok() {   # stdin must be valid JSON
    python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null && echo ok
}
item_count() { # stdin: Alfred JSON -> number of items
    python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("items",[])))' 2>/dev/null
}

echo "search.sh — empty query"
empty_out=$(./v4/search.sh "" 2>/dev/null)
assert "empty query emits valid JSON"      "$(printf '%s' "$empty_out" | json_ok)"
assert "empty query has an items array"    "$(printf '%s' "$empty_out" | jq -e 'has("items")' >/dev/null 2>&1 && echo ok)"
assert "empty query returns >=1 item"      "$(printf '%s' "$empty_out" | item_count | grep -v '^0$')"

echo "search.sh — with query"
q_out=$(./v4/search.sh "github" 2>/dev/null)
assert "query emits valid JSON"            "$(printf '%s' "$q_out" | json_ok)"
assert "query returns >=1 item"            "$(printf '%s' "$q_out" | item_count | grep -v '^0$')"
assert "results carry a cmd modifier"      "$(printf '%s' "$q_out" | jq -e '.items[0].mods.cmd' >/dev/null 2>&1 && echo ok)"
assert "results carry an alt modifier"     "$(printf '%s' "$q_out" | jq -e '.items[0].mods.alt' >/dev/null 2>&1 && echo ok)"
assert "results carry a ctrl modifier"     "$(printf '%s' "$q_out" | jq -e '.items[0].mods.ctrl' >/dev/null 2>&1 && echo ok)"
assert "results carry a match property"    "$(printf '%s' "$q_out" | jq -e '.items[0].match' >/dev/null 2>&1 && echo ok)"
assert "results declare type=file"         "$(printf '%s' "$q_out" | jq -e '.items[0].type=="file"' >/dev/null 2>&1 && echo ok)"
assert "default action variable is open"    "$(printf '%s' "$q_out" | jq -e '.items[0].variables.action=="open"' >/dev/null 2>&1 && echo ok)"
assert "modifier actions are wired"        "$(printf '%s' "$q_out" | jq -e '.items[0].mods.cmd.variables.action=="reveal" and .items[0].mods.alt.variables.action=="terminal" and .items[0].mods.ctrl.variables.action=="copy"' >/dev/null 2>&1 && echo ok)"
assert "subtitle shows eza permissions"    "$(printf '%s' "$q_out" | grep -q -- '-rw-\|-rwx\|drw' && echo ok)"

echo "dirs.sh — directories only"
d_out=$(./v4/dirs.sh "github" 2>/dev/null)
assert "dirs query emits valid JSON"       "$(printf '%s' "$d_out" | json_ok)"
assert "dirs query returns >=1 item"       "$(printf '%s' "$d_out" | item_count | grep -v '^0$')"
dirs_all_dirs=ok
while IFS= read -r p; do
    [[ -d "$p" ]] || dirs_all_dirs=""
done < <(printf '%s' "$d_out" | jq -r '.items[].arg')
assert "dirs results are all directories"  "$dirs_all_dirs"
assert "dirs empty query is valid JSON"    "$(./v4/dirs.sh "" 2>/dev/null | json_ok)"

echo "search.sh — cache & history"
cache_dir="$HOME/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/avatararsts.fzf-alfred"
assert "cache file exists"                 "$(ls "$cache_dir"/file_list.*.cache >/dev/null 2>&1 && echo ok)"

# History must record the QUERY the user typed, in an isolated data dir.
hist_dir=$(mktemp -d)
alfred_workflow_data="$hist_dir" ./v4/search.sh "uniqhistquery42" >/dev/null 2>&1
assert "history records the query"         "$(test -f "$hist_dir/history" && grep -qx 'uniqhistquery42' "$hist_dir/history" && echo ok)"
# A repeated identical query must not append a duplicate line.
alfred_workflow_data="$hist_dir" ./v4/search.sh "uniqhistquery42" >/dev/null 2>&1
assert "history dedupes adjacent queries"  "$(grep -c '^uniqhistquery42$' "$hist_dir/history" | grep -qx '1' && echo ok)"
# History must not store result paths, only queries.
assert "history stores queries not paths"  "$(grep -qv '/' "$hist_dir/history" && echo ok)"
rm -rf "$hist_dir"

echo "search.sh — search_path is honoured"
tmpdir=$(mktemp -d)
printf 'hello\n' > "$tmpdir/fzf_probe_marker.txt"
scoped=$(search_path="$tmpdir" ./v4/search.sh "fzf_probe_marker" 2>/dev/null)
assert "query honours a custom search_path" "$(printf '%s' "$scoped" | jq -e '.items[0].arg=="'"$tmpdir"'/fzf_probe_marker.txt"' >/dev/null 2>&1 && echo ok)"
rm -rf "$tmpdir"

echo "search.sh — no results"
n_out=$(./v4/search.sh "zzzznonexistent12345" 2>/dev/null)
assert "no-match query is valid JSON"      "$(printf '%s' "$n_out" | json_ok)"
assert "no-match query has 0 items"        "$(printf '%s' "$n_out" | item_count | grep -qx '0' && echo ok)"

echo "info.plist — structure"
assert "info.plist parses as a plist"      "$(plutil -lint v4/info.plist >/dev/null 2>&1 && echo ok)"
assert "script filter has keyword fzfnav"  "$(plutil -extract objects.0.config.keyword raw v4/info.plist 2>/dev/null | grep -qx fzfnav && echo ok)"
assert "script filter uses zsh (type 11)"  "$(plutil -extract objects.0.config.type raw v4/info.plist 2>/dev/null | grep -qx 11 && echo ok)"

# Every connection source/destination and every conditional output uid must resolve.
assert "connections reference existing nodes" "$(python3 - <<'PY'
import plistlib,sys
d=plistlib.load(open('v4/info.plist','rb'))
uids={o['uid'] for o in d['objects']}
cond_out={c['uid'] for o in d['objects'] if o.get('type','').endswith('conditional')
          for c in o['config']['conditions']}
ok=True
for src,links in d['connections'].items():
    if src not in uids: ok=False; print('missing source',src,file=sys.stderr)
    for l in links:
        if l['destinationuid'] not in uids: ok=False; print('missing dest',l['destinationuid'],file=sys.stderr)
        if 'sourceoutputuid' in l and l['sourceoutputuid'] not in cond_out:
            ok=False; print('bad sourceoutputuid',l['sourceoutputuid'],file=sys.stderr)
print('ok' if ok else '')
PY
)"

# The workflow graph must be complete: both filters connected, every node reachable.
assert "workflow graph is fully connected" "$(python3 - <<'PY'
import plistlib,sys
d=plistlib.load(open('v4/info.plist','rb'))
objs={o['uid']:o for o in d['objects']}
filters=[u for u,o in objs.items() if o.get('type','').endswith('input.scriptfilter')]
ok=True
# every script filter must have an outgoing connection
for f in filters:
    if f not in d['connections']: ok=False; print('filter not connected',f,file=sys.stderr)
# walk from every filter and confirm all nodes are reachable
seen=set()
stack=list(filters)
while stack:
    n=stack.pop()
    if n in seen: continue
    seen.add(n)
    for l in d['connections'].get(n,[]):
        stack.append(l['destinationuid'])
unreached=set(objs)-seen
if unreached: ok=False; print('unreachable nodes',unreached,file=sys.stderr)
# the conditional chain must terminate at an action, not dangle
for u,o in objs.items():
    if o.get('type','').endswith('conditional'):
        if u not in d['connections']: ok=False; print('conditional has no outputs',u,file=sys.stderr)
print('ok' if ok else '')
PY
)"

echo "packaging"
assert "build.sh --check succeeds"          "$(./scripts/build.sh --check >/dev/null 2>&1 && echo ok)"
extract_dir=$(mktemp -d)
unzip -q fzf-alfred.alfredworkflow -d "$extract_dir"
assert "artifact has info.plist at root"    "$(test -f "$extract_dir/info.plist" && echo ok)"
assert "artifact ships lib.sh"              "$(test -f "$extract_dir/lib.sh" && echo ok)"
assert "artifact ships dirs.sh"             "$(test -f "$extract_dir/dirs.sh" && echo ok)"
# Run exactly like Alfred does: absolute path, workflow root as cwd.
pkg_out=$(cd "$extract_dir" && "./search.sh" "README" 2>/dev/null)
assert "packaged search.sh emits valid JSON" "$(printf '%s' "$pkg_out" | json_ok)"
assert "packaged search.sh returns items"    "$(printf '%s' "$pkg_out" | item_count | grep -v '^0$')"
pkg_dir_out=$(cd "$extract_dir" && "./dirs.sh" "github" 2>/dev/null)
assert "packaged dirs.sh emits valid JSON"   "$(printf '%s' "$pkg_dir_out" | json_ok)"
rm -rf "$extract_dir"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
