#!/bin/sh
# Tests for the 'take' imp

. "${0%/*}/../test-common.sh"

test_take_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/take_test.XXXXXX")
  printf 'a\nb\nc\nd\ne\n' > "$tmpfile"
  run_spell spells/.imps/take 2 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "a"
  assert_output_contains "b"
  case "$OUTPUT" in
    *c*|*d*|*e*) TEST_FAILURE_REASON="output should not contain c, d, or e"; return 1 ;;
  esac
}

run_test_case "take from file" test_take_from_file

finish_tests
