#!/bin/sh
# Tests for the 'say' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_say_outputs() {
  run_spell spells/.imps/out/say "test message"
  assert_success
  assert_output_contains "test message"
}

test_say_handles_empty_message() {
  run_spell spells/.imps/out/say ""
  assert_success
}

run_test_case "say outputs to stdout" test_say_outputs
run_test_case "say handles empty message" test_say_handles_empty_message

finish_tests
