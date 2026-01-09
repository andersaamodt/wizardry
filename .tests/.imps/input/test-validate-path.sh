#!/bin/sh
# Test coverage for validate-path spell:
# - Shows usage with --help
# - Accepts valid paths
# - Rejects paths that are too long

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.imps/input/validate-path" --help
  assert_success || return 1
  assert_output_contains "Usage: validate-path" || return 1
}

test_accepts_simple_path() {
  run_spell "spells/.imps/input/validate-path" "/etc/passwd"
  assert_success || return 1
}

test_accepts_relative_path() {
  run_spell "spells/.imps/input/validate-path" "some/relative/path"
  assert_success || return 1
}

test_rejects_long_component() {
  # Create a component longer than 255 characters
  long_name=$(printf '%0256d' 0 | tr '0' 'a')
  run_spell "spells/.imps/input/validate-path" "/tmp/$long_name"
  assert_failure || return 1
}

run_test_case "validate-path shows usage text" test_help
run_test_case "validate-path accepts simple paths" test_accepts_simple_path
run_test_case "validate-path accepts relative paths" test_accepts_relative_path
run_test_case "validate-path rejects long path components" test_rejects_long_component


# Test via source-then-invoke pattern  

finish_tests
