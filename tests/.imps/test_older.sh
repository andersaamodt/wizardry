#!/bin/sh
# Tests for the 'older' imp

. "${0%/*}/../test_common.sh"

test_older_file() {
  old=$(mktemp "$WIZARDRY_TMPDIR/older.XXXXXX")
  sleep 1
  new=$(mktemp "$WIZARDRY_TMPDIR/newer.XXXXXX")
  run_spell spells/.imps/older "$old" "$new"
  rm -f "$old" "$new"
  assert_success
}

run_test_case "older detects older file" test_older_file

finish_tests
