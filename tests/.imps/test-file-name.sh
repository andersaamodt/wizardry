#!/bin/sh
# Tests for the 'file-name' imp

. "${0%/*}/../test-common.sh"

test_file_name_extracts() {
  run_spell spells/.imps/file-name "/path/to/file.txt"
  assert_success
  assert_output_contains "file.txt"
}

test_file_name_handles_simple_name() {
  run_spell spells/.imps/file-name "simple.txt"
  assert_success
  assert_output_contains "simple.txt"
}

run_test_case "file-name extracts filename" test_file_name_extracts
run_test_case "file-name handles simple name" test_file_name_handles_simple_name

finish_tests
