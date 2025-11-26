#!/bin/sh
# Tests for the 'skip' imp

. "${0%/*}/../test_common.sh"

test_skip_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/skip_test.XXXXXX")
  printf 'header\ndata1\ndata2\n' > "$tmpfile"
  run_spell spells/.imps/skip 1 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "data1"
  case "$OUTPUT" in
    *header*) TEST_FAILURE_REASON="output should not contain header"; return 1 ;;
  esac
}

run_test_case "skip from file" test_skip_from_file

finish_tests
