#!/bin/sh
# Tests for the 'warn' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_warn_to_stderr() {
  run_spell spells/.imps/out/warn "warning message"
  assert_success
  assert_error_contains "warning message"
}

test_warn_succeeds_with_empty_message() {
  run_spell spells/.imps/out/warn ""
  assert_success
}

run_test_case "warn outputs to stderr" test_warn_to_stderr
run_test_case "warn succeeds with empty message" test_warn_succeeds_with_empty_message

finish_tests
