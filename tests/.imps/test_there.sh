#!/bin/sh
# Tests for the 'there' and 'gone' imps

. "${0%/*}/../test_common.sh"

test_there_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/there "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_there_dir() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  run_spell spells/.imps/there "$tmpdir"
  rmdir "$tmpdir"
  assert_success
}

test_there_fails_for_missing() {
  run_spell spells/.imps/there "$WIZARDRY_TMPDIR/nonexistent_file_12345"
  assert_failure
}

test_gone_succeeds_for_nonexistent() {
  run_spell spells/.imps/gone "$WIZARDRY_TMPDIR/nonexistent_file_12345"
  assert_success
}

test_gone_fails_for_existing() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/gone "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

run_test_case "there succeeds for file" test_there_file
run_test_case "there succeeds for directory" test_there_dir
run_test_case "there fails for nonexistent" test_there_fails_for_missing
run_test_case "gone succeeds for nonexistent" test_gone_succeeds_for_nonexistent
run_test_case "gone fails for existing" test_gone_fails_for_existing

finish_tests
