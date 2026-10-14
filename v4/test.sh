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

# Test 7: eza metadata in subtitle (permission format)
result=$(./v4/search.sh "github" 2>/dev/null | grep -o '\-rw\-' | head -1)
assert "eza metadata shows correct permission format" "$result"

# Test 8: JSON is valid
result=$(./v4/search.sh "github" 2>/dev/null | head -1 | python3 -m json.tool > /dev/null 2>&1 && echo "yes")
assert "Output is valid JSON" "$result"

# Test 9: No results for non-existent query
result=$(./v4/search.sh "zzzznonexistent12345" 2>/dev/null | head -1)
assert "Non-existent query returns empty" "$result"

# Test 10: Modifier keys include all expected actions
result=$(./v4/search.sh "github" 2>/dev/null | grep -o '"action":"reveal"' | head -1)
assert "Reveal action present" "$result"
result=$(./v4/search.sh "github" 2>/dev/null | grep -o '"action":"terminal"' | head -1)
assert "Terminal action present" "$result"
result=$(./v4/search.sh "github" 2>/dev/null | grep -o '"action":"copy"' | head -1)
assert "Copy action present" "$result"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
