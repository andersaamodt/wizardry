#!/bin/sh
# Test coverage for up spell:
# - Shows usage with --help
# - Outputs cd command for one level
# - Outputs cd command for multiple levels
# - Rejects invalid input
# - Rejects extra operands

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/translocation/go-up" --help
  assert_success || return 1
  assert_output_contains "Usage: up" || return 1
}

test_default_one_level() {
  run_spell "spells/translocation/go-up"
  assert_success || return 1
  assert_output_contains 'cd ".."' || return 1
}

test_multiple_levels() {
  run_spell "spells/translocation/go-up" 3
  assert_success || return 1
  assert_output_contains 'cd "../../.."' || return 1
}

test_rejects_invalid() {
  run_spell "spells/translocation/go-up" abc
  assert_failure || return 1
  assert_error_contains "positive integer" || return 1
}

test_rejects_extra_operands() {
  run_spell "spells/translocation/go-up" 1 extra
  assert_failure || return 1
  assert_error_contains "at most one" || return 1
}

run_test_case "up shows usage text" test_help
run_test_case "up outputs cd for one level by default" test_default_one_level
run_test_case "up outputs cd for multiple levels" test_multiple_levels
run_test_case "up rejects invalid input" test_rejects_invalid
run_test_case "up rejects extra operands" test_rejects_extra_operands


# Test via source-then-invoke pattern  

finish_tests
