#!/bin/sh
# Tests for the 'file-name' imp

. "${0%/*}/../test-common.sh"

test_file_name_extracts() {
  run_spell spells/.imps/file-name "/path/to/file.txt"
  assert_success
  assert_output_contains "file.txt"
}

run_test_case "file-name extracts filename" test_file_name_extracts

finish_tests
