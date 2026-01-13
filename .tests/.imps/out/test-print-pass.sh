#!/bin/sh
# Test print-pass imp

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

print_pass_outputs_pass_message() {
  run_spell "spells/.imps/out/print-pass" "my-spell"
  assert_success || return 1
  assert_output_contains "PASS" || return 1
  assert_output_contains "my-spell" || return 1
}

print_pass_formats_correctly() {
  run_spell "spells/.imps/out/print-pass" "test-name"
  assert_success || return 1
  # Should contain "PASS test-name"
  assert_output_contains "PASS" || return 1
  assert_output_contains "test-name" || return 1
}

run_test_case "print-pass outputs PASS message" print_pass_outputs_pass_message
run_test_case "print-pass formats correctly" print_pass_formats_correctly

finish_tests
