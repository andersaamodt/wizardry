#!/bin/sh
# Tests for the 'count-chars' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_count_chars_simple() {
  _run_spell spells/.imps/text/count-chars "hello"
  _assert_success
  _assert_output_contains "5"
}

test_count_chars_empty() {
  _run_spell spells/.imps/text/count-chars ""
  _assert_success
  _assert_output_contains "0"
}

_run_test_case "count-chars counts simple string" test_count_chars_simple
_run_test_case "count-chars handles empty" test_count_chars_empty

_finish_tests
