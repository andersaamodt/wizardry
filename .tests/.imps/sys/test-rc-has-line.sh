#!/bin/sh
# Tests for the 'rc-has-line' imp

# Locate the repository root so we can source test-bootstrap
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_rc_has_line_finds_marker() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  rc_file="$tmpdir/.testrc"
  
  # Create file with marked line
  cat > "$rc_file" <<'EOF'
export PATH=/usr/bin
. "/path/to/cd" # wizardry: cd-hook
echo "test"
EOF
  
  # Should find marker
  if ! "$ROOT_DIR/spells/.imps/sys/rc-has-line" cd-hook "$rc_file"; then
    TEST_FAILURE_REASON="expected rc-has-line to find marker"
    return 1
  fi
}

test_rc_has_line_fails_when_marker_missing() {
  tmpdir=$(make_tempdir)
  rc_file="$tmpdir/.testrc"
  
  # Create file without marker
  printf 'export PATH=/usr/bin\n' > "$rc_file"
  
  # Should not find marker
  if "$ROOT_DIR/spells/.imps/sys/rc-has-line" cd-hook "$rc_file" 2>/dev/null; then
    TEST_FAILURE_REASON="expected rc-has-line to fail when marker not found"
    return 1
  fi
}

test_rc_has_line_fails_when_file_missing() {
  tmpdir=$(make_tempdir)
  rc_file="$tmpdir/.nonexistent"
  
  # Should fail on missing file
  if "$ROOT_DIR/spells/.imps/sys/rc-has-line" cd-hook "$rc_file" 2>/dev/null; then
    TEST_FAILURE_REASON="expected rc-has-line to fail on missing file"
    return 1
  fi
}

test_rc_has_line_requires_arguments() {
  tmpdir=$(make_tempdir)
  rc_file="$tmpdir/.testrc"
  touch "$rc_file"
  
  # Missing RC_FILE argument
  if "$ROOT_DIR/spells/.imps/sys/rc-has-line" marker 2>/dev/null; then
    TEST_FAILURE_REASON="expected rc-has-line to fail with missing RC_FILE argument"
    return 1
  fi
}

run_test_case "rc-has-line finds marker" test_rc_has_line_finds_marker
run_test_case "rc-has-line fails when marker missing" test_rc_has_line_fails_when_marker_missing
run_test_case "rc-has-line fails when file missing" test_rc_has_line_fails_when_file_missing
run_test_case "rc-has-line requires arguments" test_rc_has_line_requires_arguments

finish_tests
