#!/bin/sh
# Test coverage for prioritize spell:
# - Shows usage with --help
# - Requires file argument
# - Fails on missing file
# - Tests echelon functionality (requires xattr support)

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_bin() {
  dir=$(make_tempdir)
  mkdir -p "$dir/bin"
  printf '%s\n' "$dir/bin"
}

test_help() {
  run_spell "spells/priorities/prioritize" --help
  assert_success || return 1
  assert_output_contains "Usage: prioritize" || return 1
  assert_output_contains "echelon" || return 1
}

test_requires_argument() {
  run_spell "spells/priorities/prioritize"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_asks_to_create_missing_file() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/newfile.txt"
  
  # Create ask-yn stub that answers "no"
  cat >"$tmpdir/ask-yn" <<'SH'
#!/bin/sh
# Simulate answering "no"
printf '%s\n' "no"
exit 1
SH
  chmod +x "$tmpdir/ask-yn"
  
  # Run prioritize with stub that says "no"
  run_cmd env PATH="$tmpdir:$PATH" "$ROOT_DIR/spells/priorities/prioritize" "$testfile"
  assert_failure || return 1
}

test_creates_file_when_answering_yes() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/newfile.txt"
  
  # Create ask-yn stub that answers "yes"
  cat >"$tmpdir/ask-yn" <<'SH'
#!/bin/sh
# Simulate answering "yes"
printf '%s\n' "yes"
exit 0
SH
  chmod +x "$tmpdir/ask-yn"
  
  # Check if xattr support is available first
  test_existing="$tmpdir/test_existing.txt"
  printf 'test\n' > "$test_existing"
  run_spell "spells/crypto/hashchant" "$test_existing"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Run prioritize with stub that says "yes"
  run_cmd env PATH="$tmpdir:$PATH" "$ROOT_DIR/spells/priorities/prioritize" "$testfile"
  assert_success || return 1
  
  # Verify file was created
  [ -f "$testfile" ] || {
    TEST_FAILURE_REASON="File should have been created"
    return 1
  }
}

# Echelon tests require xattr support
test_first_priority() {
  # Check if xattr support is available
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test1.txt"
  printf 'test\n' > "$testfile"
  
  # Try to hash the file - if this fails, skip the test
  run_spell "spells/crypto/hashchant" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Prioritize first file
  run_spell "spells/priorities/prioritize" "$testfile"
  assert_success || return 1
  assert_output_contains "first priority" || return 1
  
  # Check echelon and priority values are both 1
  echelon=$(read-magic "$testfile" echelon 2>/dev/null || printf '0')
  priority=$(read-magic "$testfile" priority 2>/dev/null || printf '0')
  
  [ "$echelon" = "1" ] || {
    TEST_FAILURE_REASON="Expected echelon=1, got $echelon"
    return 1
  }
  
  [ "$priority" = "1" ] || {
    TEST_FAILURE_REASON="Expected priority=1, got $priority"
    return 1
  }
}

test_echelon_promotion() {
  # Check if xattr support is available
  tmpdir=$(make_tempdir)
  file1="$tmpdir/file1.txt"
  file2="$tmpdir/file2.txt"
  printf 'content1\n' > "$file1"
  printf 'content2\n' > "$file2"
  
  # Try to hash - if this fails, skip the test
  run_spell "spells/crypto/hashchant" "$file1"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Prioritize first file (creates echelon 1)
  run_spell "spells/priorities/prioritize" "$file1"
  assert_success || return 1
  
  # Prioritize second file (should move to highest echelon 1, not create new echelon)
  run_spell "spells/crypto/hashchant" "$file2"
  run_spell "spells/priorities/prioritize" "$file2"
  assert_success || return 1
  assert_output_contains "echelon 1" || return 1
  
  # Check file2 is in echelon 1
  echelon=$(read-magic "$file2" echelon 2>/dev/null || printf '0')
  [ "$echelon" = "1" ] || {
    TEST_FAILURE_REASON="Expected echelon=1, got $echelon"
    return 1
  }
}

test_already_highest() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  # Try to hash - if this fails, skip the test
  run_spell "spells/crypto/hashchant" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Prioritize file (creates echelon 1)
  run_spell "spells/priorities/prioritize" "$testfile"
  assert_success || return 1
  
  # Prioritize again - should promote to echelon 2
  run_spell "spells/priorities/prioritize" "$testfile"
  assert_success || return 1
  assert_output_contains "echelon 2" || return 1
  
  # Check echelon is now 2
  echelon=$(read-magic "$testfile" echelon 2>/dev/null || printf '0')
  [ "$echelon" = "2" ] || {
    TEST_FAILURE_REASON="Expected echelon=2 after re-prioritizing, got $echelon"
    return 1
  }
}

test_move_to_highest_echelon() {
  tmpdir=$(make_tempdir)
  file1="$tmpdir/file1.txt"
  file2="$tmpdir/file2.txt"
  file3="$tmpdir/file3.txt"
  printf 'content1\n' > "$file1"
  printf 'content2\n' > "$file2"
  printf 'content3\n' > "$file3"
  
  # Try to hash - if this fails, skip the test
  run_spell "spells/crypto/hashchant" "$file1"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Create echelon 1 with file1
  run_spell "spells/priorities/prioritize" "$file1"
  assert_success || return 1
  
  # Promote file1 to echelon 2 by prioritizing it again
  run_spell "spells/priorities/prioritize" "$file1"
  assert_success || return 1
  assert_output_contains "echelon 2" || return 1
  
  # Manually set file3 to echelon 1 (lower echelon than current highest of 2)
  run_spell "spells/crypto/hashchant" "$file3"
  enchant "$file3" echelon 1 >/dev/null
  enchant "$file3" priority 1 >/dev/null
  
  # Now prioritize file3 - should move to echelon 2 with priority 2 (after file1)
  run_spell "spells/priorities/prioritize" "$file3"
  assert_success || return 1
  assert_output_contains "echelon 2" || return 1
  
  # Check file3 is in echelon 2
  echelon=$(read-magic "$file3" echelon 2>/dev/null || printf '0')
  [ "$echelon" = "2" ] || {
    TEST_FAILURE_REASON="Expected echelon=2, got $echelon"
    return 1
  }
  
  # Check file3 has priority 2 (after file1 which has priority 1)
  priority=$(read-magic "$file3" priority 2>/dev/null || printf '0')
  [ "$priority" = "2" ] || {
    TEST_FAILURE_REASON="Expected priority=2 (added to end), got $priority"
    return 1
  }
}

test_unchecks_when_prioritizing() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  # Try to hash - if this fails, skip the test
  run_spell "spells/crypto/hashchant" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Prioritize file
  run_spell "spells/priorities/prioritize" "$testfile"
  assert_success || return 1
  
  # Check the file
  run_spell "spells/tasks/check" "$testfile"
  assert_success || return 1
  
  # Verify it's checked
  run_spell "spells/tasks/get-checked" "$testfile"
  assert_success || return 1
  assert_output_contains "1" || return 1
  
  # Prioritize again - should uncheck it
  run_spell "spells/priorities/prioritize" "$testfile"
  assert_success || return 1
  
  # Verify it's now unchecked (get-checked outputs "0" for unchecked)
  run_spell "spells/tasks/get-checked" "$testfile"
  assert_success || return 1
  assert_output_contains "0" || return 1
}

test_hash_failure_message() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  # With real xattr in CI, test that prioritize fails when hashchant fails
  stub=$(make_stub_bin)
  printf '#!/bin/sh\nexit 1\n' >"$stub/hashchant"
  chmod +x "$stub/hashchant"
  
  PATH="$WIZARDRY_IMPS_PATH:$stub:/bin:/usr/bin" run_spell "spells/priorities/prioritize" "$testfile"
  assert_failure && assert_error_contains "hashchant"
}

test_interactive_mode_prompts() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  # Create ask-text stub that returns the test file path
  cat >"$tmpdir/ask-text" <<SH
#!/bin/sh
printf '%s\n' "$testfile"
SH
  chmod +x "$tmpdir/ask-text"
  
  # Check if xattr support is available first
  run_spell "spells/crypto/hashchant" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Run prioritize in interactive mode
  run_cmd env PATH="$tmpdir:$PATH" "$ROOT_DIR/spells/priorities/prioritize" --interactive
  assert_success || return 1
  assert_output_contains "priority" || return 1
}

test_interactive_mode_with_file_arg() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  # Check if xattr support is available first
  run_spell "spells/crypto/hashchant" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Run prioritize in interactive mode with explicit file arg
  # Interactive flag should be accepted but file arg takes precedence
  run_spell "spells/priorities/prioritize" --interactive "$testfile"
  assert_success || return 1
  assert_output_contains "priority" || return 1
}

test_yes_or_y_flag_auto_creates() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/newfile.txt"
  
  # File doesn't exist yet
  [ ! -e "$testfile" ] || return 1
  
  # Run prioritize with --yes flag (no ask-yn stub needed)
  # Both --yes and -y work the same way
  run_spell "spells/priorities/prioritize" --yes "$testfile"
  
  # Check if xattr is not supported
  if [ "$STATUS" -ne 0 ]; then
    if printf '%s' "$ERROR" | grep -q "extended attributes"; then
      echo "SKIP: xattr support not available"
      return 0
    fi
    return 1
  fi
  
  assert_success || return 1
  
  # Verify file was created
  [ -e "$testfile" ] || return 1
  
  # Verify it has priority
  assert_output_contains "priority" || return 1
}

run_test_case "prioritize shows usage text with echelon mention" test_help
run_test_case "prioritize requires file argument" test_requires_argument
run_test_case "prioritize asks to create missing file" test_asks_to_create_missing_file
run_test_case "prioritize creates file when answering yes" test_creates_file_when_answering_yes
run_test_case "prioritize creates first priority" test_first_priority
run_test_case "prioritize promotes to new echelon" test_echelon_promotion
run_test_case "prioritize promotes when already in highest echelon" test_already_highest
run_test_case "prioritize moves to highest echelon when in lower echelon" test_move_to_highest_echelon
run_test_case "prioritize unchecks when prioritizing checked item" test_unchecks_when_prioritizing
run_test_case "prioritize fails with informative message when hashchant fails" test_hash_failure_message
run_test_case "prioritize --interactive prompts for file" test_interactive_mode_prompts
run_test_case "prioritize --interactive with file arg works" test_interactive_mode_with_file_arg
run_test_case "prioritize --yes/-y auto-creates missing file" test_yes_or_y_flag_auto_creates

finish_tests
