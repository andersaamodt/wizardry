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
  _run_spell "spells/.imps/out/print-fail" "my-spell"
  _assert_success || return 1
  _assert_output_contains "FAIL" || return 1
  _assert_output_contains "my-spell" || return 1
}

print_fail_includes_reason() {
  _run_spell "spells/.imps/out/print-fail" "test-spell" "missing shebang"
  _assert_success || return 1
  _assert_output_contains "FAIL" || return 1
  _assert_output_contains "test-spell" || return 1
  _assert_output_contains "missing shebang" || return 1
}

_run_test_case "print-fail outputs FAIL message" print_fail_outputs_fail_message
_run_test_case "print-fail includes reason when provided" print_fail_includes_reason

_finish_tests
