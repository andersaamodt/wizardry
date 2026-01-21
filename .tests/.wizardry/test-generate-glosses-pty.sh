#!/bin/sh
# PTY-based tests for generate-glosses with special character aliases
# Uses socat to test glosses in a realistic terminal environment

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_alias_with_number_in_pty() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  tmpdir=$(make_tempdir)
  
  # Create synonym with number at start
  cat > "$tmpdir/.synonyms" << 'EOF'
123test=echo NUMBER_ALIAS_WORKS
EOF
  
  # Generate glosses
  WIZARDRY_DIR="$ROOT_DIR" SPELLBOOK_DIR="$tmpdir" \
    run_spell spells/.wizardry/generate-glosses --output "$tmpdir/glosses.sh" --quiet
  assert_success || return 1
  
  # Create test script that sources glosses and calls the alias
  cat > "$tmpdir/test.sh" << 'SCRIPT'
#!/bin/sh
. ./glosses.sh
123test
SCRIPT
  chmod +x "$tmpdir/test.sh"
  
  # Run in PTY environment to test alias works
  cd "$tmpdir" && PTY_INPUT='' run_cmd run-with-pty sh test.sh
  assert_success || return 1
  assert_output_contains "NUMBER_ALIAS_WORKS" || return 1
}

test_alias_with_dot_in_pty() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  tmpdir=$(make_tempdir)
  
  # Create synonym with dot
  cat > "$tmpdir/.synonyms" << 'EOF'
test.dot=echo DOT_WORKS
EOF
  
  # Generate glosses
  WIZARDRY_DIR="$ROOT_DIR" SPELLBOOK_DIR="$tmpdir" \
    run_spell spells/.wizardry/generate-glosses --output "$tmpdir/glosses.sh" --quiet
  assert_success || return 1
  
  # Create test script
  cat > "$tmpdir/test.sh" << 'SCRIPT'
#!/bin/sh
. ./glosses.sh
test.dot
SCRIPT
  chmod +x "$tmpdir/test.sh"
  
  # Run in PTY
  cd "$tmpdir" && PTY_INPUT='' run_cmd run-with-pty sh test.sh
  assert_success || return 1
  assert_output_contains "DOT_WORKS" || return 1
}

test_alias_with_colon_in_pty() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  tmpdir=$(make_tempdir)
  
  # Create synonym with colon
  cat > "$tmpdir/.synonyms" << 'EOF'
test:colon=echo COLON_WORKS
EOF
  
  # Generate glosses
  WIZARDRY_DIR="$ROOT_DIR" SPELLBOOK_DIR="$tmpdir" \
    run_spell spells/.wizardry/generate-glosses --output "$tmpdir/glosses.sh" --quiet
  assert_success || return 1
  
  # Create test script
  cat > "$tmpdir/test.sh" << 'SCRIPT'
#!/bin/sh
. ./glosses.sh
test:colon
SCRIPT
  chmod +x "$tmpdir/test.sh"
  
  # Run in PTY
  cd "$tmpdir" && PTY_INPUT='' run_cmd run-with-pty sh test.sh
  assert_success || return 1
  assert_output_contains "COLON_WORKS" || return 1
}

test_alias_with_at_sign_in_pty() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  tmpdir=$(make_tempdir)
  
  # Create synonym with at sign
  cat > "$tmpdir/.synonyms" << 'EOF'
test@at=echo AT_WORKS
EOF
  
  # Generate glosses
  WIZARDRY_DIR="$ROOT_DIR" SPELLBOOK_DIR="$tmpdir" \
    run_spell spells/.wizardry/generate-glosses --output "$tmpdir/glosses.sh" --quiet
  assert_success || return 1
  
  # Create test script
  cat > "$tmpdir/test.sh" << 'SCRIPT'
#!/bin/sh
. ./glosses.sh
test@at
SCRIPT
  chmod +x "$tmpdir/test.sh"
  
  # Run in PTY
  cd "$tmpdir" && PTY_INPUT='' run_cmd run-with-pty sh test.sh
  assert_success || return 1
  assert_output_contains "AT_WORKS" || return 1
}

test_alias_with_plus_in_pty() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  tmpdir=$(make_tempdir)
  
  # Create synonym with plus
  cat > "$tmpdir/.synonyms" << 'EOF'
test+plus=echo PLUS_WORKS
EOF
  
  # Generate glosses
  WIZARDRY_DIR="$ROOT_DIR" SPELLBOOK_DIR="$tmpdir" \
    run_spell spells/.wizardry/generate-glosses --output "$tmpdir/glosses.sh" --quiet
  assert_success || return 1
  
  # Create test script
  cat > "$tmpdir/test.sh" << 'SCRIPT'
#!/bin/sh
. ./glosses.sh
test+plus
SCRIPT
  chmod +x "$tmpdir/test.sh"
  
  # Run in PTY
  cd "$tmpdir" && PTY_INPUT='' run_cmd run-with-pty sh test.sh
  assert_success || return 1
  assert_output_contains "PLUS_WORKS" || return 1
}

test_function_gloss_in_pty() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  tmpdir=$(make_tempdir)
  
  # Create synonym that can be a function (only alphanumeric and underscore)
  cat > "$tmpdir/.synonyms" << 'EOF'
testfunc=echo FUNCTION_WORKS
EOF
  
  # Generate glosses
  WIZARDRY_DIR="$ROOT_DIR" SPELLBOOK_DIR="$tmpdir" \
    run_spell spells/.wizardry/generate-glosses --output "$tmpdir/glosses.sh" --quiet
  assert_success || return 1
  
  # Verify it's a function, not an alias
  if grep -q "^alias testfunc=" "$tmpdir/glosses.sh"; then
    TEST_FAILURE_REASON="testfunc should be a function, not an alias"
    return 1
  fi
  
  if ! grep -q "^testfunc()" "$tmpdir/glosses.sh"; then
    TEST_FAILURE_REASON="testfunc function not found in glosses"
    return 1
  fi
  
  # Create test script
  cat > "$tmpdir/test.sh" << 'SCRIPT'
#!/bin/sh
. ./glosses.sh
testfunc
SCRIPT
  chmod +x "$tmpdir/test.sh"
  
  # Run in PTY to verify function works
  cd "$tmpdir" && PTY_INPUT='' run_cmd run-with-pty sh test.sh
  assert_success || return 1
  assert_output_contains "FUNCTION_WORKS" || return 1
}

test_hyphenated_alias_in_pty() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  tmpdir=$(make_tempdir)
  
  # Create hyphenated synonym
  cat > "$tmpdir/.synonyms" << 'EOF'
test-hyphen=echo HYPHEN_WORKS
EOF
  
  # Generate glosses
  WIZARDRY_DIR="$ROOT_DIR" SPELLBOOK_DIR="$tmpdir" \
    run_spell spells/.wizardry/generate-glosses --output "$tmpdir/glosses.sh" --quiet
  assert_success || return 1
  
  # Verify it's an alias (hyphens can't be in function names)
  if ! grep -q "^alias test-hyphen=" "$tmpdir/glosses.sh"; then
    TEST_FAILURE_REASON="test-hyphen should be an alias"
    return 1
  fi
  
  # Create test script
  cat > "$tmpdir/test.sh" << 'SCRIPT'
#!/bin/sh
. ./glosses.sh
test-hyphen
SCRIPT
  chmod +x "$tmpdir/test.sh"
  
  # Run in PTY
  cd "$tmpdir" && PTY_INPUT='' run_cmd run-with-pty sh test.sh
  assert_success || return 1
  assert_output_contains "HYPHEN_WORKS" || return 1
}

test_all_special_chars_in_pty() {
  # Comprehensive test of all special characters we added support for
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  tmpdir=$(make_tempdir)
  
  # Create synonyms with all supported special characters
  cat > "$tmpdir/.synonyms" << 'EOF'
a.b=echo dot
a:b=echo colon
a+b=echo plus
a,b=echo comma
a@b=echo at
a!b=echo bang
a?b=echo question
a%b=echo percent
a^b=echo caret
a~b=echo tilde
9x=echo nine
EOF
  
  # Generate glosses
  WIZARDRY_DIR="$ROOT_DIR" SPELLBOOK_DIR="$tmpdir" \
    run_spell spells/.wizardry/generate-glosses --output "$tmpdir/glosses.sh" --quiet
  assert_success || return 1
  
  # Verify all are aliases
  for name in "a.b" "a:b" "a+b" "a,b" "a@b" "a!b" "a?b" "a%b" "a^b" "a~b" "9x"; do
    if ! grep -q "^alias $name=" "$tmpdir/glosses.sh"; then
      TEST_FAILURE_REASON="alias $name not found in glosses"
      return 1
    fi
  done
  
  # Create test script that calls each one
  cat > "$tmpdir/test.sh" << 'SCRIPT'
#!/bin/sh
. ./glosses.sh
a.b
a:b
a+b
a,b
a@b
a!b
a?b
a%b
a^b
a~b
9x
SCRIPT
  chmod +x "$tmpdir/test.sh"
  
  # Run in PTY
  cd "$tmpdir" && PTY_INPUT='' run_cmd run-with-pty sh test.sh
  assert_success || return 1
  
  # Verify all outputs
  for word in dot colon plus comma at bang question percent caret tilde nine; do
    if ! printf '%s' "$OUTPUT" | grep -q "$word"; then
      TEST_FAILURE_REASON="output missing: $word"
      return 1
    fi
  done
}

run_test_case "alias with number works in PTY" test_alias_with_number_in_pty
run_test_case "alias with dot works in PTY" test_alias_with_dot_in_pty
run_test_case "alias with colon works in PTY" test_alias_with_colon_in_pty
run_test_case "alias with at-sign works in PTY" test_alias_with_at_sign_in_pty
run_test_case "alias with plus works in PTY" test_alias_with_plus_in_pty
run_test_case "function gloss works in PTY" test_function_gloss_in_pty
run_test_case "hyphenated alias works in PTY" test_hyphenated_alias_in_pty
run_test_case "all special chars work in PTY" test_all_special_chars_in_pty

finish_tests
