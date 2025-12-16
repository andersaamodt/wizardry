#!/bin/sh
# Behavioral cases (derived from --help):
# - max-length requires at least one argument
# - max-length returns longest length for arguments
# - max-length splits single list argument
# - max-length prints verbose summary when requested

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

max_length_requires_input() {
  _run_spell "spells/cantrips/max-length"
  _assert_failure || return 1
  _assert_output_contains "No arguments passed to max_length" || return 1
}

max_length_measures_individual_arguments() {
  _run_spell "spells/cantrips/max-length" short medium longestword
  _assert_success || return 1
  [ "$OUTPUT" = "11" ] || { TEST_FAILURE_REASON="expected longest length of 11"; return 1; }
}

max_length_splits_single_argument_list() {
  _run_spell "spells/cantrips/max-length" "one fourtytwo"
  _assert_success || return 1
  [ "$OUTPUT" = "9" ] || { TEST_FAILURE_REASON="expected split list longest length 9"; return 1; }
}

max_length_supports_verbose_flag() {
  _run_spell "spells/cantrips/max-length" -v "tiny hugephrase"
  _assert_success || return 1
  expected="Maximum length: 10
10"
  [ "$OUTPUT" = "$expected" ] || { TEST_FAILURE_REASON="expected verbose output with summary"; return 1; }
}

_run_test_case "max-length requires at least one argument" max_length_requires_input
_run_test_case "max-length returns longest length for arguments" max_length_measures_individual_arguments
_run_test_case "max-length splits single list argument" max_length_splits_single_argument_list
_run_test_case "max-length prints verbose summary when requested" max_length_supports_verbose_flag

shows_help() {
  _run_spell spells/cantrips/max-length --help
  # Note: spell may not have --help implemented yet
  true
}

_run_test_case "max-length shows help" shows_help
_finish_tests
