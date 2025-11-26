#!/bin/sh
# Tests for additional imp coverage - failure modes and edge cases

. "${0%/*}/../test_common.sh"

# drop additional tests
test_drop_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/drop_test.XXXXXX")
  printf 'a\nb\nc\nd\ne\n' > "$tmpfile"
  run_spell spells/.imps/drop 2 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "a"
  assert_output_contains "b"
  assert_output_contains "c"
  case "$OUTPUT" in
    *d*|*e*) TEST_FAILURE_REASON="output should not contain d or e"; return 1 ;;
  esac
}

test_drop_all_lines() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/drop_test.XXXXXX")
  printf 'a\nb\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | $ROOT_DIR/spells/.imps/drop 10"
  rm -f "$tmpfile"
  assert_success
  # Output should be empty when dropping more lines than exist
  case "$OUTPUT" in
    '') return 0 ;;
    *) TEST_FAILURE_REASON="output should be empty"; return 1 ;;
  esac
}

# take additional tests
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

test_take_from_stdin() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/take_test.XXXXXX")
  printf 'line1\nline2\nline3\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | $ROOT_DIR/spells/.imps/take 1"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "line1"
  case "$OUTPUT" in
    *line2*|*line3*) TEST_FAILURE_REASON="output should only contain first line"; return 1 ;;
  esac
}

# skip additional tests
test_skip_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/skip_test.XXXXXX")
  printf 'header\ndata1\ndata2\n' > "$tmpfile"
  run_spell spells/.imps/skip 1 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "data1"
  assert_output_contains "data2"
  case "$OUTPUT" in
    *header*) TEST_FAILURE_REASON="output should not contain header"; return 1 ;;
  esac
}

test_skip_from_stdin() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/skip_test.XXXXXX")
  printf 'a\nb\nc\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | $ROOT_DIR/spells/.imps/skip 2"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "c"
  case "$OUTPUT" in
    *a*|*b*) TEST_FAILURE_REASON="output should not contain a or b"; return 1 ;;
  esac
}

# pick additional tests
test_pick_from_stdin() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/pick_test.XXXXXX")
  printf 'one\ntwo\nthree\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | $ROOT_DIR/spells/.imps/pick 2"
  rm -f "$tmpfile"
  assert_success
  case "$OUTPUT" in
    *two*) return 0 ;;
    *) TEST_FAILURE_REASON="should output 'two', got: $OUTPUT"; return 1 ;;
  esac
}

test_pick_last_line() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/pick_test.XXXXXX")
  printf 'a\nb\nc\n' > "$tmpfile"
  run_spell spells/.imps/pick 3 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  case "$OUTPUT" in
    *c*) return 0 ;;
    *) TEST_FAILURE_REASON="should output 'c', got: $OUTPUT"; return 1 ;;
  esac
}

# make additional tests
test_make_unknown_type_fails() {
  run_spell spells/.imps/make unknown "$WIZARDRY_TMPDIR/test_$$"
  assert_failure
}

test_make_dir_nested() {
  nested_dir="$WIZARDRY_TMPDIR/make_nested_$$/deep/path"
  run_spell spells/.imps/make dir "$nested_dir"
  assert_success
  if [ ! -d "$nested_dir" ]; then
    TEST_FAILURE_REASON="nested directory should be created"
    rm -rf "$WIZARDRY_TMPDIR/make_nested_$$"
    return 1
  fi
  rm -rf "$WIZARDRY_TMPDIR/make_nested_$$"
}

# lines additional tests
test_lines_empty_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/lines_test.XXXXXX")
  : > "$tmpfile"
  run_spell spells/.imps/lines "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "0"
}

test_lines_from_stdin() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/lines_test.XXXXXX")
  printf 'a\nb\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | $ROOT_DIR/spells/.imps/lines"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "2"
}

# last from stdin test
test_last_from_stdin() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/last_test.XXXXXX")
  printf 'first\nmiddle\nlast\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | $ROOT_DIR/spells/.imps/last"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "last"
}

# field additional tests
test_field_out_of_range() {
  # Getting field beyond available columns - should output empty
  run_cmd sh -c "printf 'a:b' | '$ROOT_DIR/spells/.imps/field' 5 ':'"
  assert_success
  # Output should be empty or just whitespace
}

run_test_case "drop removes from file" test_drop_from_file
run_test_case "drop handles more than available" test_drop_all_lines
run_test_case "take from file" test_take_from_file
run_test_case "take from stdin" test_take_from_stdin
run_test_case "skip from file" test_skip_from_file
run_test_case "skip from stdin" test_skip_from_stdin
run_test_case "pick from stdin" test_pick_from_stdin
run_test_case "pick last line" test_pick_last_line
run_test_case "make unknown type fails" test_make_unknown_type_fails
run_test_case "make nested directories" test_make_dir_nested
run_test_case "lines empty file" test_lines_empty_file
run_test_case "lines from stdin" test_lines_from_stdin
run_test_case "last from stdin" test_last_from_stdin
run_test_case "field out of range" test_field_out_of_range

finish_tests
