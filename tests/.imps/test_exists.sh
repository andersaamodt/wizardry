#!/bin/sh
# Tests for the 'exists' and 'missing' imps

. "${0%/*}/../test_common.sh"

test_exists_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/exists "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_exists_dir() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  run_spell spells/.imps/exists "$tmpdir"
  rmdir "$tmpdir"
  assert_success
}

test_exists_fails_for_missing() {
  run_spell spells/.imps/exists "$WIZARDRY_TMPDIR/nonexistent_file_12345"
  assert_failure
}

test_missing_succeeds_for_nonexistent() {
  run_spell spells/.imps/missing "$WIZARDRY_TMPDIR/nonexistent_file_12345"
  assert_success
}

test_missing_fails_for_existing() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/missing "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

run_test_case "exists succeeds for file" test_exists_file
run_test_case "exists succeeds for directory" test_exists_dir
run_test_case "exists fails for nonexistent" test_exists_fails_for_missing
run_test_case "missing succeeds for nonexistent" test_missing_succeeds_for_nonexistent
run_test_case "missing fails for existing" test_missing_fails_for_existing

finish_tests
