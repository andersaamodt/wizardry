#!/bin/sh
# Tests for line manipulation imps: skip, take, where

. "${0%/*}/../test_common.sh"

# skip tests
test_skip_first_n_lines() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/skip_test.XXXXXX")
  printf '1\n2\n3\n4\n5\n' > "$tmpfile"
  run_spell spells/.imps/skip 2 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  case "$OUTPUT" in
    *1*|*2*) TEST_FAILURE_REASON="should have skipped lines 1 and 2"; return 1 ;;
    *3*4*5*) return 0 ;;
    *) TEST_FAILURE_REASON="expected lines 3,4,5, got: $OUTPUT"; return 1 ;;
  esac
}

test_skip_from_stdin() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/skip_test.XXXXXX")
  printf 'header\ndata1\ndata2\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | '$ROOT_DIR/spells/.imps/skip' 1"
  rm -f "$tmpfile"
  assert_success
  case "$OUTPUT" in
    *header*) TEST_FAILURE_REASON="should have skipped header"; return 1 ;;
    *data1*data2*) return 0 ;;
    *) TEST_FAILURE_REASON="expected data lines"; return 1 ;;
  esac
}

test_skip_zero_lines() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/skip_test.XXXXXX")
  printf 'a\nb\n' > "$tmpfile"
  run_spell spells/.imps/skip 0 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "a"
  assert_output_contains "b"
}

# take tests
test_take_first_n_lines() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/take_test.XXXXXX")
  printf '1\n2\n3\n4\n5\n' > "$tmpfile"
  run_spell spells/.imps/take 2 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "1"
  assert_output_contains "2"
  case "$OUTPUT" in
    *3*|*4*|*5*) TEST_FAILURE_REASON="should not contain lines after first 2"; return 1 ;;
  esac
}

test_take_from_stdin() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/take_test.XXXXXX")
  printf 'line1\nline2\nline3\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | '$ROOT_DIR/spells/.imps/take' 1"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "line1"
  case "$OUTPUT" in
    *line2*|*line3*) TEST_FAILURE_REASON="should only take first line"; return 1 ;;
  esac
}

test_take_more_than_available() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/take_test.XXXXXX")
  printf 'only\ntwo\n' > "$tmpfile"
  run_spell spells/.imps/take 10 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "only"
  assert_output_contains "two"
}

# where tests
test_where_finds_command() {
  run_spell spells/.imps/where sh
  assert_success
  case "$OUTPUT" in
    /*sh*) return 0 ;;
    *) TEST_FAILURE_REASON="expected path to sh, got: $OUTPUT"; return 1 ;;
  esac
}

test_where_fails_for_missing() {
  run_spell spells/.imps/where nonexistent_command_xyz123456
  assert_failure
}

test_where_outputs_path() {
  run_spell spells/.imps/where cat
  assert_success
  # Should be an absolute path
  case "$OUTPUT" in
    /*) return 0 ;;
    *) TEST_FAILURE_REASON="expected absolute path, got: $OUTPUT"; return 1 ;;
  esac
}

run_test_case "skip first N lines from file" test_skip_first_n_lines
run_test_case "skip from stdin" test_skip_from_stdin
run_test_case "skip zero lines" test_skip_zero_lines
run_test_case "take first N lines from file" test_take_first_n_lines
run_test_case "take from stdin" test_take_from_stdin
run_test_case "take more than available" test_take_more_than_available
run_test_case "where finds command" test_where_finds_command
run_test_case "where fails for missing" test_where_fails_for_missing
run_test_case "where outputs path" test_where_outputs_path

finish_tests
