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
  _run_spell spells/.imps/paths/file-name "/path/to/file.txt"
  _assert_success
  _assert_output_contains "file.txt"
}

test_file_name_handles_simple_name() {
  _run_spell spells/.imps/paths/file-name "simple.txt"
  _assert_success
  _assert_output_contains "simple.txt"
}

_run_test_case "file-name extracts filename" test_file_name_extracts
_run_test_case "file-name handles simple name" test_file_name_handles_simple_name

_finish_tests
