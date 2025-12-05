#!/bin/sh
# Tests for the 'any' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_any_finds_first() {
  run_spell spells/.imps/sys/any sh nonexistent_xyz
  assert_success
  assert_output_contains "sh"
}

test_any_finds_second() {
  run_spell spells/.imps/sys/any nonexistent_xyz sh
  assert_success
  assert_output_contains "sh"
}

test_any_fails_when_none_exist() {
  run_spell spells/.imps/sys/any nonexistent_xyz1 nonexistent_xyz2
  assert_failure
}

run_test_case "any finds first available" test_any_finds_first
run_test_case "any finds second if first missing" test_any_finds_second
run_test_case "any fails when none exist" test_any_fails_when_none_exist

finish_tests
