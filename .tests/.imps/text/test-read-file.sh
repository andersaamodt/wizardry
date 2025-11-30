#!/bin/sh
# Tests for the 'read-file' imp

. "${0%/*}/../../test-common.sh"

test_read_file_outputs_content() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/readfile_test.XXXXXX")
  printf 'test content' > "$tmpfile"
  run_spell spells/.imps/text/read-file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "test content"
}

test_read_file_handles_empty_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/readfile_test.XXXXXX")
  : > "$tmpfile"
  run_spell spells/.imps/text/read-file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "read-file outputs content" test_read_file_outputs_content
run_test_case "read-file handles empty file" test_read_file_handles_empty_file

finish_tests
