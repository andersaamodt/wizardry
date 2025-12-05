#!/bin/sh
# Tests for the 'make' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_make_dir() {
  tmpdir="$WIZARDRY_TMPDIR/make_test_$$"
  "$ROOT_DIR/spells/.imps/paths/make" dir "$tmpdir"
  if [ -d "$tmpdir" ]; then
    rm -rf "$tmpdir"
    return 0
  fi
  TEST_FAILURE_REASON="make dir should create directory"
  return 1
}

test_make_unknown_type_fails() {
  run_spell spells/.imps/paths/make unknown "$WIZARDRY_TMPDIR/test_$$"
  assert_failure
}

run_test_case "make dir creates directory" test_make_dir
run_test_case "make unknown type fails" test_make_unknown_type_fails

finish_tests
