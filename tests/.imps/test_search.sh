#!/bin/sh
# Tests for new imps: field, matches, and comprehensive tests for seeks

. "${0%/*}/../test_common.sh"

# field tests
test_field_with_delimiter() {
  run_cmd sh -c "printf 'a:b:c' | '$ROOT_DIR/spells/.imps/field' 2 ':'"
  assert_success
  case "$OUTPUT" in
    b) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'b', got: $OUTPUT"; return 1 ;;
  esac
}

test_field_first_field() {
  run_cmd sh -c "printf 'first:second:third' | '$ROOT_DIR/spells/.imps/field' 1 ':'"
  assert_success
  case "$OUTPUT" in
    first) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'first', got: $OUTPUT"; return 1 ;;
  esac
}

test_field_whitespace_default() {
  run_cmd sh -c "printf 'one two three' | '$ROOT_DIR/spells/.imps/field' 2"
  assert_success
  case "$OUTPUT" in
    two) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'two', got: $OUTPUT"; return 1 ;;
  esac
}

test_field_tab_delimiter() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/field_test.XXXXXX")
  printf 'a\tb\tc\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | '$ROOT_DIR/spells/.imps/field' 3"
  rm -f "$tmpfile"
  assert_success
  case "$OUTPUT" in
    *c*) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'c', got: $OUTPUT"; return 1 ;;
  esac
}

test_field_rejects_invalid_n() {
  run_cmd sh -c "printf 'a:b:c' | '$ROOT_DIR/spells/.imps/field' 'abc' ':'"
  assert_failure
}

test_field_rejects_empty_n() {
  run_cmd sh -c "printf 'a:b:c' | '$ROOT_DIR/spells/.imps/field' '' ':'"
  assert_failure
}

# matches tests
test_matches_finds_regex() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/matches_test.XXXXXX")
  printf 'ID=nixos\nVERSION=23.11\n' > "$tmpfile"
  run_spell spells/.imps/matches "^ID=nixos" "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_matches_fails_for_no_match() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/matches_test.XXXXXX")
  printf 'ID=debian\nVERSION=12\n' > "$tmpfile"
  run_spell spells/.imps/matches "^ID=nixos" "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

test_matches_finds_pattern_anywhere() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/matches_test.XXXXXX")
  printf 'some text\nerror found here\nmore text\n' > "$tmpfile"
  run_spell spells/.imps/matches "error" "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_matches_fails_for_missing_file() {
  run_spell spells/.imps/matches "pattern" "$WIZARDRY_TMPDIR/nonexistent_xyz123"
  assert_failure
}

# seeks tests (comprehensive)
test_seeks_finds_literal() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/seeks_test.XXXXXX")
  printf 'hello world\n' > "$tmpfile"
  run_spell spells/.imps/seeks "world" "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_seeks_fails_for_missing_pattern() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/seeks_test.XXXXXX")
  printf 'hello world\n' > "$tmpfile"
  run_spell spells/.imps/seeks "xyz" "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

test_seeks_handles_special_chars() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/seeks_test.XXXXXX")
  printf '# wizardry PATH begin\n' > "$tmpfile"
  run_spell spells/.imps/seeks "# wizardry PATH begin" "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_seeks_fails_for_missing_file() {
  run_spell spells/.imps/seeks "pattern" "$WIZARDRY_TMPDIR/nonexistent_xyz123"
  assert_failure
}

run_test_case "field extracts with delimiter" test_field_with_delimiter
run_test_case "field extracts first field" test_field_first_field
run_test_case "field uses whitespace default" test_field_whitespace_default
run_test_case "field handles tab delimiter" test_field_tab_delimiter
run_test_case "field rejects invalid n" test_field_rejects_invalid_n
run_test_case "field rejects empty n" test_field_rejects_empty_n
run_test_case "matches finds regex" test_matches_finds_regex
run_test_case "matches fails for no match" test_matches_fails_for_no_match
run_test_case "matches finds pattern anywhere" test_matches_finds_pattern_anywhere
run_test_case "matches fails for missing file" test_matches_fails_for_missing_file
run_test_case "seeks finds literal" test_seeks_finds_literal
run_test_case "seeks fails for missing pattern" test_seeks_fails_for_missing_pattern
run_test_case "seeks handles special chars" test_seeks_handles_special_chars
run_test_case "seeks fails for missing file" test_seeks_fails_for_missing_file

finish_tests
