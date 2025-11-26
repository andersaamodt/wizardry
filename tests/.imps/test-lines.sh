#!/bin/sh
# Tests for the 'lines' imp

. "${0%/*}/../test-common.sh"

test_lines_counts() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'one\ntwo\nthree\n' > "$tmpfile"
  run_spell spells/.imps/lines "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "3"
}

test_lines_handles_empty_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  : > "$tmpfile"
  run_spell spells/.imps/lines "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "0"
}

run_test_case "lines counts correctly" test_lines_counts
run_test_case "lines handles empty file" test_lines_handles_empty_file

finish_tests
