#!/bin/sh
# Tests for the 'say' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_say_outputs() {
  skip-if-compiled || return $?
  _run_spell spells/.imps/out/say "test message"
  _assert_success
  _assert_output_contains "test message"
}

test_say_handles_empty_message() {
  _run_spell spells/.imps/out/say ""
  _assert_success
}

_run_test_case "say outputs to stdout" test_say_outputs
_run_test_case "say handles empty message" test_say_handles_empty_message

_finish_tests
