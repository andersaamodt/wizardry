#!/bin/sh
# Tests for the 'drop' imp

. "${0%/*}/../test_common.sh"

test_drop_removes_last_lines() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/drop_test.XXXXXX")
  printf 'a\nb\nc\nd\ne\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | $ROOT_DIR/spells/.imps/drop 2"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "a"
  assert_output_contains "b"
  assert_output_contains "c"
  case "$OUTPUT" in
    *d*|*e*) TEST_FAILURE_REASON="output should not contain d or e"; return 1 ;;
  esac
}

run_test_case "drop removes last N lines" test_drop_removes_last_lines

finish_tests
