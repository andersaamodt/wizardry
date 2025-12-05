#!/bin/sh
# Test coverage for validate-number spell:
# - Shows usage with --help
# - Accepts valid numbers
# - Rejects non-numbers
# - Rejects empty input

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_help() {
  run_spell "spells/cantrips/validate-number" --help
  assert_success || return 1
  assert_output_contains "Usage: validate-number" || return 1
}

test_accepts_valid_number() {
  run_spell "spells/cantrips/validate-number" 123
  assert_success || return 1
}

test_accepts_zero() {
  run_spell "spells/cantrips/validate-number" 0
  assert_success || return 1
}

test_rejects_letters() {
  run_spell "spells/cantrips/validate-number" abc
  assert_failure || return 1
}

test_rejects_mixed() {
  run_spell "spells/cantrips/validate-number" 12abc
  assert_failure || return 1
}

test_rejects_empty() {
  run_spell "spells/cantrips/validate-number" ""
  assert_failure || return 1
}

run_test_case "validate-number shows usage text" test_help
run_test_case "validate-number accepts valid numbers" test_accepts_valid_number
run_test_case "validate-number accepts zero" test_accepts_zero
run_test_case "validate-number rejects letters" test_rejects_letters
run_test_case "validate-number rejects mixed input" test_rejects_mixed
run_test_case "validate-number rejects empty input" test_rejects_empty

finish_tests
