#!/bin/sh
# Tests for the 'first' imp

. "${0%/*}/../test_common.sh"

test_first_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'first\nsecond\n' > "$tmpfile"
  run_spell spells/.imps/first "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "first"
}

run_test_case "first reads from file" test_first_from_file

finish_tests
