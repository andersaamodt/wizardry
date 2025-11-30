#!/bin/sh
# Tests for the 'newer' imp

. "${0%/*}/../../test-common.sh"

test_newer_file() {
  old=$(mktemp "$WIZARDRY_TMPDIR/older.XXXXXX")
  sleep 1
  new=$(mktemp "$WIZARDRY_TMPDIR/newer.XXXXXX")
  run_spell spells/.imps/cond/newer "$new" "$old"
  rm -f "$old" "$new"
  assert_success
}

test_newer_fails_for_older_file() {
  old=$(mktemp "$WIZARDRY_TMPDIR/older.XXXXXX")
  sleep 1
  new=$(mktemp "$WIZARDRY_TMPDIR/newer.XXXXXX")
  run_spell spells/.imps/cond/newer "$old" "$new"
  rm -f "$old" "$new"
  assert_failure
}

run_test_case "newer detects newer file" test_newer_file
run_test_case "newer fails for older file" test_newer_fails_for_older_file

finish_tests
