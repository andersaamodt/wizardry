#!/bin/sh
# Tests for the 'pick' imp

. "${0%/*}/../test_common.sh"

test_pick_selects_line() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/pick_test.XXXXXX")
  printf 'one\ntwo\nthree\n' > "$tmpfile"
  run_spell spells/.imps/pick 2 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "two"
}

run_test_case "pick selects line by number" test_pick_selects_line

finish_tests
