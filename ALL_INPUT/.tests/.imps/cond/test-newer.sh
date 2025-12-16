#!/bin/sh
# Tests for the 'newer' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_newer_file() {
  old=$(mktemp "$WIZARDRY_TMPDIR/older.XXXXXX")
  sleep 1
  new=$(mktemp "$WIZARDRY_TMPDIR/newer.XXXXXX")
  _run_spell spells/.imps/cond/newer "$new" "$old"
  rm -f "$old" "$new"
  _assert_success
}

test_newer_fails_for_older_file() {
  old=$(mktemp "$WIZARDRY_TMPDIR/older.XXXXXX")
  sleep 1
  new=$(mktemp "$WIZARDRY_TMPDIR/newer.XXXXXX")
  _run_spell spells/.imps/cond/newer "$old" "$new"
  rm -f "$old" "$new"
  _assert_failure
}

_run_test_case "newer detects newer file" test_newer_file
_run_test_case "newer fails for older file" test_newer_fails_for_older_file

_finish_tests
