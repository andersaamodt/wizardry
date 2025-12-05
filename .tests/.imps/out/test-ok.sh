#!/bin/sh
# Tests for the 'ok' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_ok_succeeds_when_command_succeeds() {
  run_spell spells/.imps/out/ok true
  assert_success
}

test_ok_fails_when_command_fails() {
  run_spell spells/.imps/out/ok false
  assert_failure
}

run_test_case "ok succeeds when command succeeds" test_ok_succeeds_when_command_succeeds
run_test_case "ok fails when command fails" test_ok_fails_when_command_fails

finish_tests
