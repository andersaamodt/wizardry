#!/bin/sh
# Tests for the 'parent' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_parent_extracts() {
  run_spell spells/.imps/paths/parent "/path/to/file.txt"
  assert_success
  assert_output_contains "/path/to"
}

test_parent_handles_simple_file() {
  run_spell spells/.imps/paths/parent "file.txt"
  assert_success
  assert_output_contains "."
}

run_test_case "parent extracts directory" test_parent_extracts
run_test_case "parent handles simple file" test_parent_handles_simple_file

finish_tests
