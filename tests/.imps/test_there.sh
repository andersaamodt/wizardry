#!/bin/sh
# Tests for the 'there' imp

. "${0%/*}/../test_common.sh"

test_there_exists() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/there_test.XXXXXX")
  run_spell spells/.imps/there "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_there_missing() {
  run_spell spells/.imps/there "$WIZARDRY_TMPDIR/nonexistent_xyz123"
  assert_failure
}

run_test_case "there succeeds for existing path" test_there_exists
run_test_case "there fails for missing path" test_there_missing

finish_tests
