#!/bin/sh
# Tests for the 'on' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_on_linux() {
  _run_spell spells/.imps/sys/on linux
  # This should succeed on Linux, fail on other platforms
  # Either way it should not crash
  [ "$STATUS" -eq 0 ] || [ "$STATUS" -eq 1 ]
}

test_on_unknown_fails() {
  _run_spell spells/.imps/sys/on unknownplatform
  _assert_failure
}

_run_test_case "on linux checks platform" test_on_linux
_run_test_case "on unknown fails" test_on_unknown_fails

_finish_tests
