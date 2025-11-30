#!/bin/sh
# Tests for the 'matches' imp

. "${0%/*}/../../test-common.sh"

test_matches_pattern() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/matches_test.XXXXXX")
  printf 'hello123\n' > "$tmpfile"
  run_spell spells/.imps/str/matches "[a-z]*[0-9]*" "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_matches_rejects_nonmatch() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/matches_test.XXXXXX")
  printf 'hello\n' > "$tmpfile"
  run_spell spells/.imps/str/matches "^[0-9]+$" "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

run_test_case "matches finds pattern" test_matches_pattern
run_test_case "matches rejects non-match" test_matches_rejects_nonmatch

finish_tests
