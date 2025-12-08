#!/bin/sh
# Tests for the 'there' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_there_exists() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/there_test.XXXXXX")
  _run_spell spells/.imps/cond/there "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
}

test_there_missing() {
  skip-if-compiled || return $?
  _run_spell spells/.imps/cond/there "$WIZARDRY_TMPDIR/nonexistent_xyz123"
  _assert_failure
}

_run_test_case "there succeeds for existing path" test_there_exists
_run_test_case "there fails for missing path" test_there_missing

_finish_tests
