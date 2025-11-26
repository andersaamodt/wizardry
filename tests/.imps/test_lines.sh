#!/bin/sh
# Tests for the 'lines' imp

. "${0%/*}/../test_common.sh"

test_lines_counts() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'one\ntwo\nthree\n' > "$tmpfile"
  run_spell spells/.imps/lines "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "3"
}

run_test_case "lines counts correctly" test_lines_counts

finish_tests
