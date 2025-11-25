#!/bin/sh
# Tests for data flow imps: first, last, lines, trim, lower, each, else, or

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

test_last_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'first\nsecond\nlast\n' > "$tmpfile"
  run_spell spells/.imps/last "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "last"
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

test_else_uses_default() {
  run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/else' 'fallback'"
  assert_success
  assert_output_contains "fallback"
}

test_else_passes_through() {
  run_cmd sh -c "printf 'original' | '$ROOT_DIR/spells/.imps/else' 'fallback'"
  assert_success
  assert_output_contains "original"
}

test_or_first() {
  run_spell spells/.imps/or "first" "second"
  assert_success
  assert_output_contains "first"
}

test_or_second() {
  run_spell spells/.imps/or "" "second"
  assert_success
  assert_output_contains "second"
}

test_or_fails_both_empty() {
  run_spell spells/.imps/or "" ""
  assert_failure
}

test_upper_converts() {
  run_cmd sh -c "printf 'hello' | '$ROOT_DIR/spells/.imps/upper'"
  assert_success
  assert_output_contains "HELLO"
}

test_upper_mixed_case() {
  run_cmd sh -c "printf 'HeLLo WoRLd' | '$ROOT_DIR/spells/.imps/upper'"
  assert_success
  assert_output_contains "HELLO WORLD"
}

test_lower_mixed_case() {
  run_cmd sh -c "printf 'HeLLo WoRLd' | '$ROOT_DIR/spells/.imps/lower'"
  assert_success
  assert_output_contains "hello world"
}

test_trim_leading() {
  run_cmd sh -c "printf '   leading' | '$ROOT_DIR/spells/.imps/trim'"
  assert_success
  case "$OUTPUT" in
    leading) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'leading', got: '$OUTPUT'"; return 1 ;;
  esac
}

test_trim_trailing() {
  run_cmd sh -c "printf 'trailing   ' | '$ROOT_DIR/spells/.imps/trim'"
  assert_success
  case "$OUTPUT" in
    trailing) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'trailing', got: '$OUTPUT'"; return 1 ;;
  esac
}

run_test_case "first reads from stdin" test_first_from_stdin
run_test_case "first reads from file" test_first_from_file
run_test_case "last reads from file" test_last_from_file
run_test_case "lines counts correctly" test_lines_counts
run_test_case "trim removes whitespace" test_trim_removes_whitespace
run_test_case "trim removes leading" test_trim_leading
run_test_case "trim removes trailing" test_trim_trailing
run_test_case "lower converts to lowercase" test_lower_converts
run_test_case "lower handles mixed case" test_lower_mixed_case
run_test_case "upper converts to uppercase" test_upper_converts
run_test_case "upper handles mixed case" test_upper_mixed_case
run_test_case "each runs for each line" test_each_runs_for_lines
run_test_case "else uses default for empty" test_else_uses_default
run_test_case "else passes through non-empty" test_else_passes_through
run_test_case "or returns first non-empty" test_or_first
run_test_case "or returns second if first empty" test_or_second
run_test_case "or fails if both empty" test_or_fails_both_empty

finish_tests
