#!/bin/sh
# Tests for the 'rc-add-line' imp

# Locate the repository root so we can source test-bootstrap
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_rc_add_line_creates_file_and_adds_line() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  rc_file="$tmpdir/.testrc"
  
  # Add a line to non-existent file
  result=$("$ROOT_DIR/spells/.imps/sys/rc-add-line" cd-hook "$rc_file" '. "/path/to/cd"' 2>&1) || {
    TEST_FAILURE_REASON="rc-add-line failed: $result"
    return 1
  }
  
  # Verify file was created
  if [ ! -f "$rc_file" ]; then
    TEST_FAILURE_REASON="expected rc file to be created"
    return 1
  fi
  
  # Verify line with inline marker was added
  if ! grep -qF '. "/path/to/cd" # wizardry: cd-hook' "$rc_file"; then
    TEST_FAILURE_REASON="expected line with inline marker in file"
    return 1
  fi
}

test_rc_add_line_is_idempotent() {
  tmpdir=$(make_tempdir)
  rc_file="$tmpdir/.testrc"
  
  # Add line twice
  "$ROOT_DIR/spells/.imps/sys/rc-add-line" cd-hook "$rc_file" '. "/path/to/cd"'
  "$ROOT_DIR/spells/.imps/sys/rc-add-line" cd-hook "$rc_file" '. "/path/to/cd"'
  
  # Count markers - should be exactly 1
  marker_count=$(grep -c "# wizardry: cd-hook" "$rc_file" || printf '0')
  if [ "$marker_count" -ne 1 ]; then
    TEST_FAILURE_REASON="expected exactly 1 marker, found $marker_count"
    return 1
  fi
}

test_rc_add_line_appends_to_existing_file() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  rc_file="$tmpdir/.testrc"
  
  # Create file with existing content
  printf 'export PATH=/usr/bin\n' > "$rc_file"
  
  # Add line
  "$ROOT_DIR/spells/.imps/sys/rc-add-line" test-marker "$rc_file" 'echo "test"'
  
  # Verify original content preserved
  if ! grep -q "export PATH=/usr/bin" "$rc_file"; then
    TEST_FAILURE_REASON="expected original content to be preserved"
    return 1
  fi
  
  # Verify new line added
  if ! grep -qF 'echo "test" # wizardry: test-marker' "$rc_file"; then
    TEST_FAILURE_REASON="expected new line with marker"
    return 1
  fi
}

test_rc_add_line_requires_all_arguments() {
  tmpdir=$(make_tempdir)
  rc_file="$tmpdir/.testrc"
  
  # Missing LINE argument
  if "$ROOT_DIR/spells/.imps/sys/rc-add-line" marker "$rc_file" 2>/dev/null; then
    TEST_FAILURE_REASON="expected rc-add-line to fail with missing LINE argument"
    return 1
  fi
  
  # Missing RC_FILE argument
  if "$ROOT_DIR/spells/.imps/sys/rc-add-line" marker 2>/dev/null; then
    TEST_FAILURE_REASON="expected rc-add-line to fail with missing RC_FILE argument"
    return 1
  fi
}

run_test_case "rc-add-line creates file and adds line" test_rc_add_line_creates_file_and_adds_line
run_test_case "rc-add-line is idempotent" test_rc_add_line_is_idempotent
run_test_case "rc-add-line appends to existing file" test_rc_add_line_appends_to_existing_file
run_test_case "rc-add-line requires all arguments" test_rc_add_line_requires_all_arguments

finish_tests
