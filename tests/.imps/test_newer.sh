#!/bin/sh
# Tests for the 'newer' imp

. "${0%/*}/../test_common.sh"

test_newer_file() {
  old=$(mktemp "$WIZARDRY_TMPDIR/older.XXXXXX")
  sleep 1
  new=$(mktemp "$WIZARDRY_TMPDIR/newer.XXXXXX")
  run_spell spells/.imps/newer "$new" "$old"
  rm -f "$old" "$new"
  assert_success
}

run_test_case "newer detects newer file" test_newer_file

finish_tests
