#!/bin/sh
# Tests for the 'parent' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

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
