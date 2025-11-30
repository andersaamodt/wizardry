#!/bin/sh
# Tests for the 'pick' imp

. "${0%/*}/../../test-common.sh"

test_pick_selects_line() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/pick_test.XXXXXX")
  printf 'one\ntwo\nthree\n' > "$tmpfile"
  run_spell spells/.imps/text/pick 2 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "two"
}

test_pick_selects_first_line() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/pick_test.XXXXXX")
  printf 'first\nsecond\n' > "$tmpfile"
  run_spell spells/.imps/text/pick 1 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "first"
}

run_test_case "pick selects line by number" test_pick_selects_line
run_test_case "pick selects first line" test_pick_selects_first_line

finish_tests
