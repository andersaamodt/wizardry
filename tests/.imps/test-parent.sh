#!/bin/sh
# Tests for the 'parent' imp

. "${0%/*}/../test-common.sh"

test_parent_extracts() {
  run_spell spells/.imps/parent "/path/to/file.txt"
  assert_success
  assert_output_contains "/path/to"
}

run_test_case "parent extracts directory" test_parent_extracts

finish_tests
