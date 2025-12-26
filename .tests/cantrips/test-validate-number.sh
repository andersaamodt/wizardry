#!/bin/sh
# Test coverage for validate-number spell:
# - Shows usage with --help
# - Accepts valid numbers
# - Rejects non-numbers
# - Rejects empty input

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/cantrips/validate-number" --help
  _assert_success || return 1
  _assert_output_contains "Usage: validate-number" || return 1
}

test_accepts_valid_number() {
  _run_spell "spells/cantrips/validate-number" 123
  _assert_success || return 1
}

test_accepts_zero() {
  _run_spell "spells/cantrips/validate-number" 0
  _assert_success || return 1
}

test_rejects_letters() {
  _run_spell "spells/cantrips/validate-number" abc
  _assert_failure || return 1
}

test_rejects_mixed() {
  _run_spell "spells/cantrips/validate-number" 12abc
  _assert_failure || return 1
}

test_rejects_empty() {
  _run_spell "spells/cantrips/validate-number" ""
  _assert_failure || return 1
}

_run_test_case "validate-number shows usage text" test_help
_run_test_case "validate-number accepts valid numbers" test_accepts_valid_number
_run_test_case "validate-number accepts zero" test_accepts_zero
_run_test_case "validate-number rejects letters" test_rejects_letters
_run_test_case "validate-number rejects mixed input" test_rejects_mixed
_run_test_case "validate-number rejects empty input" test_rejects_empty


# Test via source-then-invoke pattern  
validate_number_help_via_sourcing() {
  _run_sourced_spell validate-number --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "validate-number works via source-then-invoke" validate_number_help_via_sourcing
_finish_tests
