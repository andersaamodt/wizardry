#!/bin/sh
# Tests for data flow imps: first, lines, trim, lower, each, otherwise, either

. "${0%/*}/../test_common.sh"

test_first_from_stdin() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'line1\nline2\nline3\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | '$ROOT_DIR/spells/.imps/first'"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "line1"
}

test_first_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'first\nsecond\n' > "$tmpfile"
  run_spell spells/.imps/first "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "first"
}

test_lines_counts() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'one\ntwo\nthree\n' > "$tmpfile"
  run_spell spells/.imps/lines "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "3"
}

test_trim_removes_whitespace() {
  run_cmd sh -c "printf '  hello  ' | '$ROOT_DIR/spells/.imps/trim'"
  assert_success
  assert_output_contains "hello"
}

test_lower_converts() {
  run_cmd sh -c "printf 'HELLO' | '$ROOT_DIR/spells/.imps/lower'"
  assert_success
  assert_output_contains "hello"
}

test_each_runs_for_lines() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'a\nb\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | '$ROOT_DIR/spells/.imps/each' echo 'item:'"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "item: a"
  assert_output_contains "item: b"
}

test_otherwise_uses_default() {
  run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/otherwise' 'fallback'"
  assert_success
  assert_output_contains "fallback"
}

test_otherwise_passes_through() {
  run_cmd sh -c "printf 'original' | '$ROOT_DIR/spells/.imps/otherwise' 'fallback'"
  assert_success
  assert_output_contains "original"
}

test_either_first() {
  run_spell spells/.imps/either "first" "second"
  assert_success
  assert_output_contains "first"
}

test_either_second() {
  run_spell spells/.imps/either "" "second"
  assert_success
  assert_output_contains "second"
}

test_either_fails_both_empty() {
  run_spell spells/.imps/either "" ""
  assert_failure
}

run_test_case "first reads from stdin" test_first_from_stdin
run_test_case "first reads from file" test_first_from_file
run_test_case "lines counts correctly" test_lines_counts
run_test_case "trim removes whitespace" test_trim_removes_whitespace
run_test_case "lower converts to lowercase" test_lower_converts
run_test_case "each runs for each line" test_each_runs_for_lines
run_test_case "otherwise uses default for empty" test_otherwise_uses_default
run_test_case "otherwise passes through non-empty" test_otherwise_passes_through
run_test_case "either returns first non-empty" test_either_first
run_test_case "either returns second if first empty" test_either_second
run_test_case "either fails if both empty" test_either_fails_both_empty

finish_tests
