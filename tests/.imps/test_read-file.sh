#!/bin/sh
# Tests for the 'read-file' imp

. "${0%/*}/../test_common.sh"

test_read_file_outputs_content() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/readfile_test.XXXXXX")
  printf 'test content' > "$tmpfile"
  run_spell spells/.imps/read-file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "test content"
}

run_test_case "read-file outputs content" test_read_file_outputs_content

finish_tests
