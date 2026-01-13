#!/bin/sh
# Tests for the 'rc-remove-line' imp

# Locate the repository root so we can source test-bootstrap
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_rc_remove_line_removes_marked_lines() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  rc_file="$tmpdir/.testrc"
  
  # Create file with marked line
  cat > "$rc_file" <<'EOF'
export PATH=/usr/bin
. "/path/to/cd" # wizardry: cd-hook
echo "test"
EOF
  
  # Remove marked line
  result=$("$ROOT_DIR/spells/.imps/sys/rc-remove-line" cd-hook "$rc_file" 2>&1) || {
    TEST_FAILURE_REASON="rc-remove-line failed: $result"
    return 1
  }
  
  # Verify marked line removed
  if grep -qF "# wizardry: cd-hook" "$rc_file"; then
    TEST_FAILURE_REASON="expected marked line to be removed"
    return 1
  fi
  
  # Verify other content preserved
  if ! grep -q "export PATH=/usr/bin" "$rc_file"; then
    TEST_FAILURE_REASON="expected original content to be preserved"
    return 1
  fi
  if ! grep -q 'echo "test"' "$rc_file"; then
    TEST_FAILURE_REASON="expected original content to be preserved"
    return 1
  fi
}

test_rc_remove_line_handles_missing_file() {
  tmpdir=$(make_tempdir)
  rc_file="$tmpdir/.nonexistent"
  
  # Should succeed (nothing to remove)
  if ! "$ROOT_DIR/spells/.imps/sys/rc-remove-line" cd-hook "$rc_file" 2>/dev/null; then
    TEST_FAILURE_REASON="expected rc-remove-line to succeed on missing file"
    return 1
  fi
}

test_rc_remove_line_handles_missing_marker() {
  tmpdir=$(make_tempdir)
  rc_file="$tmpdir/.testrc"
  
  # Create file without marker
  printf 'export PATH=/usr/bin\n' > "$rc_file"
  
  # Should succeed (nothing to remove)
  if ! "$ROOT_DIR/spells/.imps/sys/rc-remove-line" cd-hook "$rc_file" 2>/dev/null; then
    TEST_FAILURE_REASON="expected rc-remove-line to succeed when marker not found"
    return 1
  fi
  
  # Verify content unchanged
  if ! grep -q "export PATH=/usr/bin" "$rc_file"; then
    TEST_FAILURE_REASON="expected content to be unchanged"
    return 1
  fi
}

test_rc_remove_line_requires_arguments() {
  tmpdir=$(make_tempdir)
  rc_file="$tmpdir/.testrc"
  
  # Missing RC_FILE argument
  if "$ROOT_DIR/spells/.imps/sys/rc-remove-line" marker 2>/dev/null; then
    TEST_FAILURE_REASON="expected rc-remove-line to fail with missing RC_FILE argument"
    return 1
  fi
}

run_test_case "rc-remove-line removes marked lines" test_rc_remove_line_removes_marked_lines
run_test_case "rc-remove-line handles missing file" test_rc_remove_line_handles_missing_file
run_test_case "rc-remove-line handles missing marker" test_rc_remove_line_handles_missing_marker
run_test_case "rc-remove-line requires arguments" test_rc_remove_line_requires_arguments

finish_tests
