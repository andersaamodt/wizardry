#!/bin/sh
# Test parse collision detection between first-word glosses and system commands

# Standalone test (no test-bootstrap dependency)
test_count=0
passed=0
failed=0

assert_contains() {
  test_count=$((test_count + 1))
  if printf '%s' "$1" | grep -q "$2"; then
    printf 'PASS #%d: %s\n' "$test_count" "$3"
    passed=$((passed + 1))
    return 0
  else
    printf 'FAIL #%d: %s\n' "$test_count" "$3"
    printf '  Expected to contain: %s\n' "$2"
    printf '  Got: %s\n' "$1"
    failed=$((failed + 1))
    return 1
  fi
}

assert_exit_success() {
  test_count=$((test_count + 1))
  if [ "$1" -eq 0 ]; then
    printf 'PASS #%d: %s\n' "$test_count" "$2"
    passed=$((passed + 1))
    return 0
  else
    printf 'FAIL #%d: %s (exit code %d)\n' "$test_count" "$2" "$1"
    failed=$((failed + 1))
    return 1
  fi
}

tmpdir=/tmp/parse_collision_test_$$
mkdir -p "$tmpdir/wizardry/spells/.imps/sys"

# Test 1: When ONLY multi-word wizardry commands exist, calling single word should fall through to system
# Example: User has env-or and env-clear, but calls just "env"
# Expected: Should call system /usr/bin/env, not error

cat > "$tmpdir/wizardry/spells/.imps/sys/env-or" <<'EOF'
#!/bin/sh
printf 'env-or called\n'
EOF
chmod +x "$tmpdir/wizardry/spells/.imps/sys/env-or"

cat > "$tmpdir/wizardry/spells/.imps/sys/env-clear" <<'EOF'
#!/bin/sh
printf 'env-clear called\n'
EOF
chmod +x "$tmpdir/wizardry/spells/.imps/sys/env-clear"

export WIZARDRY_DIR="$tmpdir/wizardry"
export HOME=/tmp

# Call just "env" without any multi-word match
# This simulates: env() { parse "env" "$@"; } with user typing just "env"
output=$(sh /home/runner/work/wizardry/wizardry/spells/.imps/lex/parse "env" 2>&1)
code=$?

# Should successfully call system env (which outputs env vars)
assert_exit_success "$code" "Single-word falls through to system command when no single-word wizardry spell"
# System env should output at least PATH
assert_contains "$output" "PATH=" "System env command executes and outputs env vars"

# Test 2: When wizardry has BOTH single-word and multi-word spells
# Example: User has both "env" spell and "env-or" spell
# Calling just "env" should call the wizardry env spell, not system env

cat > "$tmpdir/wizardry/spells/.imps/sys/env" <<'EOF'
#!/bin/sh
printf 'WIZARDRY_ENV_CALLED\n'
EOF
chmod +x "$tmpdir/wizardry/spells/.imps/sys/env"

output=$(sh /home/runner/work/wizardry/wizardry/spells/.imps/lex/parse "env" 2>&1)
code=$?
assert_exit_success "$code" "Single-word wizardry spell executes when it exists"
assert_contains "$output" "WIZARDRY_ENV_CALLED" "Wizardry env spell is called, not system env"

# Test 3: Multi-word command with extra args should still work
output=$(sh /home/runner/work/wizardry/wizardry/spells/.imps/lex/parse "env" "or" "VAR" "DEFAULT" 2>&1)
code=$?
assert_exit_success "$code" "Multi-word command works alongside single-word spell"
assert_contains "$output" "env-or called" "env-or is called when multi-word pattern matches"

# Test 4: When NO wizardry spells exist for a command, fall through to system
rm -rf "$tmpdir/wizardry/spells/.imps/sys/env"*

output=$(sh /home/runner/work/wizardry/wizardry/spells/.imps/lex/parse "ls" "/" 2>&1)
code=$?
assert_exit_success "$code" "System commands work when no wizardry spells exist"

# Test 5: First-word gloss with args that don't form valid multi-word command
# Example: env() { parse "env" "$@"; } with user typing "env somefile.txt"
# Should fall through to system env with somefile.txt as arg
# Note: system env will try to execute somefile.txt as a command

mkdir -p "$tmpdir/wizardry/spells/.imps/sys"
cat > "$tmpdir/wizardry/spells/.imps/sys/env-or" <<'EOF'
#!/bin/sh
printf 'env-or called\n'
EOF
chmod +x "$tmpdir/wizardry/spells/.imps/sys/env-or"

# "env file" doesn't match any multi-word spell
# System env will try to execute "file" command
output=$(sh /home/runner/work/wizardry/wizardry/spells/.imps/lex/parse "env" "file" 2>&1)
code=$?
# The file command should execute (via env) and might output usage or run successfully
# The key point is that env-or was NOT called
if printf '%s' "$output" | grep -q "env-or"; then
  test_count=$((test_count + 1))
  printf 'FAIL #%d: Should not match env-or when user typed "env file"\n' "$test_count"
  failed=$((failed + 1))
else
  test_count=$((test_count + 1))
  printf 'PASS #%d: Does not incorrectly match env-or for "env file"\n' "$test_count"
  passed=$((passed + 1))
fi

# Cleanup
rm -rf "$tmpdir"

# Summary
printf '\n%d/%d tests passed\n' "$passed" "$test_count"
if [ "$failed" -gt 0 ]; then
  printf '%d tests FAILED\n' "$failed"
  exit 1
else
  printf 'All tests PASSED\n'
  exit 0
fi
