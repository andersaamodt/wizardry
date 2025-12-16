#!/bin/sh
# Test test-heading imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_basic_heading() {
  output=$(_test_heading 5 10 "test-spell")
  echo "$output" | grep -q "^\[5/10\] test-spell$"
}

test_outputs_heading_with_suffix() {
  output=$(_test_heading 3 8 "test-spell (skipped: reason)")
  echo "$output" | grep -q "^\[3/8\] test-spell (skipped: reason)$"
}

test_handles_special_chars() {
  output=$(_test_heading 1 2 "test's-spell")
  echo "$output" | grep -q "^\[1/2\] test's-spell$"
}

_run_test_case "test-heading outputs basic heading" test_outputs_basic_heading
_run_test_case "test-heading outputs heading with suffix in name" test_outputs_heading_with_suffix
_run_test_case "test-heading handles special characters" test_handles_special_chars

_finish_tests
