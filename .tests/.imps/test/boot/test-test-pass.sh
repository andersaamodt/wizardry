#!/bin/sh
# Test test-pass imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_pass_message() {
  output=$(_test_pass "test description")
  echo "$output" | grep -q "^PASS test description$"
}

test_handles_special_chars() {
  output=$(_test_pass "test with 'quotes' and spaces")
  echo "$output" | grep -q "PASS test with 'quotes' and spaces"
}

_run_test_case "test-pass outputs PASS message" test_outputs_pass_message
_run_test_case "test-pass handles special characters" test_handles_special_chars

_finish_tests
