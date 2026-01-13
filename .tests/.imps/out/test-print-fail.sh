#!/bin/sh
# Test print-fail imp

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

print_fail_outputs_fail_message() {
  run_spell "spells/.imps/out/print-fail" "my-spell"
  assert_success || return 1
  assert_output_contains "FAIL" || return 1
  assert_output_contains "my-spell" || return 1
}

print_fail_includes_reason() {
  run_spell "spells/.imps/out/print-fail" "test-spell" "missing shebang"
  assert_success || return 1
  assert_output_contains "FAIL" || return 1
  assert_output_contains "test-spell" || return 1
  assert_output_contains "missing shebang" || return 1
}

print_fail_handles_empty_reason() {
  run_spell "spells/.imps/out/print-fail" "test-spell" ""
  assert_success || return 1
  assert_output_contains "FAIL" || return 1
  assert_output_contains "test-spell" || return 1
  # Should not have a colon when reason is empty
  case "$OUTPUT" in
    *": "*) TEST_FAILURE_REASON="should not contain colon with empty reason"; return 1 ;;
  esac
}

run_test_case "print-fail outputs FAIL message" print_fail_outputs_fail_message
run_test_case "print-fail includes reason when provided" print_fail_includes_reason
run_test_case "print-fail handles empty reason" print_fail_handles_empty_reason

finish_tests
