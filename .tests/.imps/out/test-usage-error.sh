#!/bin/sh
# Tests for the 'usage-error' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_usage_error_exits_with_code_2() {
  skip-if-compiled || return $?
  run_spell spells/.imps/out/usage-error "my-spell" "invalid option"
  assert_status 2
}

test_usage_error_formats_message_with_name() {
  skip-if-compiled || return $?
  run_spell spells/.imps/out/usage-error "my-spell" "unknown option: -x"
  assert_status 2
  assert_error_contains "my-spell: unknown option: -x"
}

test_usage_error_handles_missing_name() {
  skip-if-compiled || return $?
  run_spell spells/.imps/out/usage-error "" "some error"
  assert_status 2
  assert_error_contains "some error"
}

test_usage_error_handles_empty_args() {
  skip-if-compiled || return $?
  run_spell spells/.imps/out/usage-error "" ""
  assert_status 2
}

test_usage_error_uses_default_message_when_empty() {
  skip-if-compiled || return $?
  run_spell spells/.imps/out/usage-error "my-spell" ""
  assert_status 2
  assert_error_contains "my-spell: usage error"
}

run_test_case "usage-error exits with code 2" test_usage_error_exits_with_code_2
run_test_case "usage-error formats message with spell name" test_usage_error_formats_message_with_name
run_test_case "usage-error handles missing name" test_usage_error_handles_missing_name
run_test_case "usage-error handles empty args" test_usage_error_handles_empty_args
run_test_case "usage-error uses default message when empty" test_usage_error_uses_default_message_when_empty

finish_tests
