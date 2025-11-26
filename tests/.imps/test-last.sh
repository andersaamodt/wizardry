#!/bin/sh
# Tests for the 'last' imp

. "${0%/*}/../test-common.sh"

test_last_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'first\nsecond\nlast\n' > "$tmpfile"
  run_spell spells/.imps/last "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "last"
}

run_test_case "last reads from file" test_last_from_file

finish_tests
