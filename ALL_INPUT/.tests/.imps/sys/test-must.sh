#!/bin/sh
# Tests for the 'must' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_must_file_exists() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/must_test.XXXXXX")
  _run_spell spells/.imps/sys/must file "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
}

test_must_file_fails_for_missing() {
  _run_spell spells/.imps/sys/must file "$WIZARDRY_TMPDIR/nonexistent_xyz123"
  _assert_failure
  _assert_error_contains "file not found"
}

_run_test_case "must file succeeds for existing file" test_must_file_exists
_run_test_case "must file fails for missing" test_must_file_fails_for_missing

_finish_tests
