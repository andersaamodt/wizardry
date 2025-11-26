#!/bin/sh
# Tests for the 'each' imp

. "${0%/*}/../test_common.sh"

test_each_runs_for_lines() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'a\nb\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | '$ROOT_DIR/spells/.imps/each' echo 'item:'"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "item: a"
  assert_output_contains "item: b"
}

run_test_case "each runs for each line" test_each_runs_for_lines

finish_tests
