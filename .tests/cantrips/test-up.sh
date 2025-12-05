#!/bin/sh
# Test coverage for up spell:
# - Shows usage with --help
# - Outputs cd command for one level
# - Outputs cd command for multiple levels
# - Rejects invalid input

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_help() {
  run_spell "spells/cantrips/up" --help
  assert_success || return 1
  assert_output_contains "Usage: up" || return 1
}

test_default_one_level() {
  run_spell "spells/cantrips/up"
  assert_success || return 1
  assert_output_contains 'cd ".."' || return 1
}

test_multiple_levels() {
  run_spell "spells/cantrips/up" 3
  assert_success || return 1
  assert_output_contains 'cd "../../.."' || return 1
}

test_rejects_invalid() {
  run_spell "spells/cantrips/up" abc
  assert_failure || return 1
  assert_error_contains "positive integer" || return 1
}

run_test_case "up shows usage text" test_help
run_test_case "up outputs cd for one level by default" test_default_one_level
run_test_case "up outputs cd for multiple levels" test_multiple_levels
run_test_case "up rejects invalid input" test_rejects_invalid

finish_tests
