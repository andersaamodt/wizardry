#!/bin/sh
# Tests for the 'field' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_field_with_delimiter() {
  run_cmd sh -c "printf 'a:b:c' | '$ROOT_DIR/spells/.imps/text/field' 2 ':'"
  assert_success
  assert_output_contains "b"
}

test_field_whitespace_default() {
  run_cmd sh -c "printf 'one two three' | '$ROOT_DIR/spells/.imps/text/field' 2"
  assert_success
  assert_output_contains "two"
}

run_test_case "field extracts with delimiter" test_field_with_delimiter
run_test_case "field uses whitespace default" test_field_whitespace_default

finish_tests
