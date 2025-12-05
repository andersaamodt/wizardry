#!/bin/sh
# Tests for the 'any' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_any_finds_first() {
  _run_spell spells/.imps/sys/any sh nonexistent_xyz
  _assert_success
  _assert_output_contains "sh"
}

test_any_finds_second() {
  _run_spell spells/.imps/sys/any nonexistent_xyz sh
  _assert_success
  _assert_output_contains "sh"
}

test_any_fails_when_none_exist() {
  _run_spell spells/.imps/sys/any nonexistent_xyz1 nonexistent_xyz2
  _assert_failure
}

_run_test_case "any finds first available" test_any_finds_first
_run_test_case "any finds second if first missing" test_any_finds_second
_run_test_case "any fails when none exist" test_any_fails_when_none_exist

_finish_tests
