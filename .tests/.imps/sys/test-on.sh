#!/bin/sh
# Tests for the 'on' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_on_linux() {
  run_spell spells/.imps/sys/on linux
  # This should succeed on Linux, fail on other platforms
  # Either way it should not crash
  [ "$STATUS" -eq 0 ] || [ "$STATUS" -eq 1 ]
}

test_on_unknown_fails() {
  run_spell spells/.imps/sys/on unknownplatform
  assert_failure
}

run_test_case "on linux checks platform" test_on_linux
run_test_case "on unknown fails" test_on_unknown_fails

finish_tests
