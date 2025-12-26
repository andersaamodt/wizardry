#!/bin/sh
# Test coverage for up spell:
# - Shows usage with --help
# - Outputs cd command for one level
# - Outputs cd command for multiple levels
# - Rejects invalid input

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/cantrips/up" --help
  _assert_success || return 1
  _assert_output_contains "Usage: up" || return 1
}

test_default_one_level() {
  _run_spell "spells/cantrips/up"
  _assert_success || return 1
  _assert_output_contains 'cd ".."' || return 1
}

test_multiple_levels() {
  _run_spell "spells/cantrips/up" 3
  _assert_success || return 1
  _assert_output_contains 'cd "../../.."' || return 1
}

test_rejects_invalid() {
  _run_spell "spells/cantrips/up" abc
  _assert_failure || return 1
  _assert_error_contains "positive integer" || return 1
}

_run_test_case "up shows usage text" test_help
_run_test_case "up outputs cd for one level by default" test_default_one_level
_run_test_case "up outputs cd for multiple levels" test_multiple_levels
_run_test_case "up rejects invalid input" test_rejects_invalid


# Test via source-then-invoke pattern  
