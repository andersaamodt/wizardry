#!/bin/sh
# Tests for the 'die' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_die_exits_with_message() {
  run_spell spells/.imps/out/die "fatal error"
  assert_failure
  assert_error_contains "fatal error"
}

test_die_accepts_custom_exit_code() {
  run_spell spells/.imps/out/die 42 "custom code"
  [ "$STATUS" -eq 42 ] || { TEST_FAILURE_REASON="expected status 42, got $STATUS"; return 1; }
}

run_test_case "die exits with message" test_die_exits_with_message
run_test_case "die accepts custom exit code" test_die_accepts_custom_exit_code

finish_tests
