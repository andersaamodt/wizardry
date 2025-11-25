#!/bin/sh
# Tests for file operation imps: append, read-file, write-file, path, norm-path, here

. "${0%/*}/../test_common.sh"

# append tests
test_append_adds_to_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/append_test.XXXXXX")
  printf 'initial\n' > "$tmpfile"
  run_cmd sh -c "printf 'appended' | '$ROOT_DIR/spells/.imps/append' '$tmpfile'"
  content=$(cat "$tmpfile")
  rm -f "$tmpfile"
  assert_success
  case "$content" in
    *initial*appended*) return 0 ;;
    *) TEST_FAILURE_REASON="expected both initial and appended content"; return 1 ;;
  esac
}

test_append_creates_file() {
  tmpfile="$WIZARDRY_TMPDIR/append_new_$$"
  rm -f "$tmpfile"
  run_cmd sh -c "printf 'newcontent' | '$ROOT_DIR/spells/.imps/append' '$tmpfile'"
  content=$(cat "$tmpfile" 2>/dev/null || echo "")
  rm -f "$tmpfile"
  assert_success
  case "$content" in
    *newcontent*) return 0 ;;
    *) TEST_FAILURE_REASON="expected newcontent in file"; return 1 ;;
  esac
}

# read-file tests
test_read_file_outputs_content() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/read_test.XXXXXX")
  printf 'file content here' > "$tmpfile"
  run_spell spells/.imps/read-file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "file content here"
}

test_read_file_fails_for_missing() {
  run_spell spells/.imps/read-file "$WIZARDRY_TMPDIR/nonexistent_file_xyz123"
  assert_failure
}

# write-file tests
test_write_file_creates() {
  tmpfile="$WIZARDRY_TMPDIR/write_test_$$"
  rm -f "$tmpfile"
  run_cmd sh -c "printf 'written content' | '$ROOT_DIR/spells/.imps/write-file' '$tmpfile'"
  content=$(cat "$tmpfile" 2>/dev/null || echo "")
  rm -f "$tmpfile"
  assert_success
  case "$content" in
    *written*) return 0 ;;
    *) TEST_FAILURE_REASON="expected written content in file"; return 1 ;;
  esac
}

test_write_file_overwrites() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/write_test.XXXXXX")
  printf 'old content' > "$tmpfile"
  run_cmd sh -c "printf 'new content' | '$ROOT_DIR/spells/.imps/write-file' '$tmpfile'"
  content=$(cat "$tmpfile")
  rm -f "$tmpfile"
  assert_success
  case "$content" in
    *old*) TEST_FAILURE_REASON="old content should be overwritten"; return 1 ;;
    *new*) return 0 ;;
    *) TEST_FAILURE_REASON="expected new content"; return 1 ;;
  esac
}

# path tests (absolute path conversion)
test_path_converts_relative() {
  run_spell spells/.imps/path "somefile.txt"
  assert_success
  case "$OUTPUT" in
    /*somefile.txt) return 0 ;;
    *) TEST_FAILURE_REASON="expected absolute path ending in somefile.txt, got: $OUTPUT"; return 1 ;;
  esac
}

test_path_preserves_absolute() {
  run_spell spells/.imps/path "/absolute/path/file.txt"
  assert_success
  case "$OUTPUT" in
    /absolute/path/file.txt) return 0 ;;
    *) TEST_FAILURE_REASON="expected /absolute/path/file.txt, got: $OUTPUT"; return 1 ;;
  esac
}

test_path_normalizes_slashes() {
  run_spell spells/.imps/path "/path///to//file.txt"
  assert_success
  case "$OUTPUT" in
    */path/to/file.txt) return 0 ;;
    *) TEST_FAILURE_REASON="expected normalized slashes, got: $OUTPUT"; return 1 ;;
  esac
}

# norm-path tests
test_norm_path_collapses_slashes() {
  run_spell spells/.imps/norm-path "/path///to//file.txt"
  assert_success
  case "$OUTPUT" in
    /path/to/file.txt) return 0 ;;
    *) TEST_FAILURE_REASON="expected /path/to/file.txt, got: $OUTPUT"; return 1 ;;
  esac
}

test_norm_path_from_stdin() {
  run_cmd sh -c "printf '/a//b///c' | '$ROOT_DIR/spells/.imps/norm-path'"
  assert_success
  case "$OUTPUT" in
    /a/b/c) return 0 ;;
    *) TEST_FAILURE_REASON="expected /a/b/c, got: $OUTPUT"; return 1 ;;
  esac
}

# here tests
test_here_outputs_cwd() {
  run_spell spells/.imps/here
  assert_success
  # Output should be a valid directory
  case "$OUTPUT" in
    /*) return 0 ;;
    *) TEST_FAILURE_REASON="expected absolute path, got: $OUTPUT"; return 1 ;;
  esac
}

test_here_matches_pwd() {
  expected=$(pwd -P)
  run_spell spells/.imps/here
  assert_success
  # Allow for minor normalization differences
  case "$OUTPUT" in
    "$expected"*) return 0 ;;
    *) TEST_FAILURE_REASON="expected $expected, got: $OUTPUT"; return 1 ;;
  esac
}

run_test_case "append adds to file" test_append_adds_to_file
run_test_case "append creates file" test_append_creates_file
run_test_case "read-file outputs content" test_read_file_outputs_content
run_test_case "read-file fails for missing" test_read_file_fails_for_missing
run_test_case "write-file creates" test_write_file_creates
run_test_case "write-file overwrites" test_write_file_overwrites
run_test_case "path converts relative" test_path_converts_relative
run_test_case "path preserves absolute" test_path_preserves_absolute
run_test_case "path normalizes slashes" test_path_normalizes_slashes
run_test_case "norm-path collapses slashes" test_norm_path_collapses_slashes
run_test_case "norm-path from stdin" test_norm_path_from_stdin
run_test_case "here outputs cwd" test_here_outputs_cwd
run_test_case "here matches pwd" test_here_matches_pwd

finish_tests
