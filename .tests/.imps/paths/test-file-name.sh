#!/bin/sh
# Tests for the 'file-name' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_file_name_extracts() {
  run_spell spells/.imps/paths/file-name "/path/to/file.txt"
  assert_success
  assert_output_contains "file.txt"
}

test_file_name_handles_simple_name() {
  run_spell spells/.imps/paths/file-name "simple.txt"
  assert_success
  assert_output_contains "simple.txt"
}

run_test_case "file-name extracts filename" test_file_name_extracts
run_test_case "file-name handles simple name" test_file_name_handles_simple_name

finish_tests
