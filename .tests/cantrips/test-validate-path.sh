#!/bin/sh
# Test coverage for validate-path spell:
# - Shows usage with --help
# - Accepts valid paths
# - Rejects paths that are too long

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_help() {
  run_spell "spells/cantrips/validate-path" --help
  assert_success || return 1
  assert_output_contains "Usage: validate-path" || return 1
}

test_accepts_simple_path() {
  run_spell "spells/cantrips/validate-path" "/etc/passwd"
  assert_success || return 1
}

test_accepts_relative_path() {
  run_spell "spells/cantrips/validate-path" "some/relative/path"
  assert_success || return 1
}

test_rejects_long_component() {
  # Create a component longer than 255 characters
  long_name=$(printf '%0256d' 0 | tr '0' 'a')
  run_spell "spells/cantrips/validate-path" "/tmp/$long_name"
  assert_failure || return 1
}

run_test_case "validate-path shows usage text" test_help
run_test_case "validate-path accepts simple paths" test_accepts_simple_path
run_test_case "validate-path accepts relative paths" test_accepts_relative_path
run_test_case "validate-path rejects long path components" test_rejects_long_component

finish_tests
