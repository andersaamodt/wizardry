#!/bin/sh
# Tests for the 'older' imp

. "${0%/*}/../test-common.sh"

test_older_file() {
  old=$(mktemp "$WIZARDRY_TMPDIR/older.XXXXXX")
  sleep 1
  new=$(mktemp "$WIZARDRY_TMPDIR/newer.XXXXXX")
  run_spell spells/.imps/older "$old" "$new"
  rm -f "$old" "$new"
  assert_success
}

test_older_fails_for_newer_file() {
  old=$(mktemp "$WIZARDRY_TMPDIR/older.XXXXXX")
  sleep 1
  new=$(mktemp "$WIZARDRY_TMPDIR/newer.XXXXXX")
  run_spell spells/.imps/older "$new" "$old"
  rm -f "$old" "$new"
  assert_failure
}

run_test_case "older detects older file" test_older_file
run_test_case "older fails for newer file" test_older_fails_for_newer_file

finish_tests
