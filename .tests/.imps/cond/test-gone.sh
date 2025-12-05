#!/bin/sh
# Tests for the 'gone' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_gone_missing() {
  _run_spell spells/.imps/cond/gone "$WIZARDRY_TMPDIR/nonexistent_xyz123"
  _assert_success
}

test_gone_exists() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/gone_test.XXXXXX")
  _run_spell spells/.imps/cond/gone "$tmpfile"
  rm -f "$tmpfile"
  _assert_failure
}

_run_test_case "gone succeeds for missing path" test_gone_missing
_run_test_case "gone fails for existing path" test_gone_exists

_finish_tests
