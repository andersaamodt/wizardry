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
  _run_spell "spells/cantrips/validate-path" --help
  _assert_success || return 1
  _assert_output_contains "Usage: validate-path" || return 1
}

test_accepts_simple_path() {
  _run_spell "spells/cantrips/validate-path" "/etc/passwd"
  _assert_success || return 1
}

test_accepts_relative_path() {
  _run_spell "spells/cantrips/validate-path" "some/relative/path"
  _assert_success || return 1
}

test_rejects_long_component() {
  # Create a component longer than 255 characters
  long_name=$(printf '%0256d' 0 | tr '0' 'a')
  _run_spell "spells/cantrips/validate-path" "/tmp/$long_name"
  _assert_failure || return 1
}

_run_test_case "validate-path shows usage text" test_help
_run_test_case "validate-path accepts simple paths" test_accepts_simple_path
_run_test_case "validate-path accepts relative paths" test_accepts_relative_path
_run_test_case "validate-path rejects long path components" test_rejects_long_component

_finish_tests
