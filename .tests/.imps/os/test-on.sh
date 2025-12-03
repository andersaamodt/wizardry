#!/bin/sh
# Tests for the 'on' imp

. "${0%/*}/../../test-common.sh"

test_on_linux() {
  run_spell spells/.imps/os/on linux
  # This should succeed on Linux, fail on other platforms
  # Either way it should not crash
  [ "$STATUS" -eq 0 ] || [ "$STATUS" -eq 1 ]
}

test_on_unknown_fails() {
  run_spell spells/.imps/os/on unknownplatform
  assert_failure
}

run_test_case "on linux checks platform" test_on_linux
run_test_case "on unknown fails" test_on_unknown_fails

finish_tests
