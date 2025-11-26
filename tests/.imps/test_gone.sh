#!/bin/sh
# Tests for the 'gone' imp

. "${0%/*}/../test_common.sh"

test_gone_missing() {
  run_spell spells/.imps/gone "$WIZARDRY_TMPDIR/nonexistent_xyz123"
  assert_success
}

test_gone_exists() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/gone_test.XXXXXX")
  run_spell spells/.imps/gone "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

run_test_case "gone succeeds for missing path" test_gone_missing
run_test_case "gone fails for existing path" test_gone_exists

finish_tests
