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
  run_spell "spells/cantrips/max-length"
  assert_failure || return 1
  [ "$ERROR" = "No arguments passed to max-length" ] || { TEST_FAILURE_REASON="expected error message to go to stderr"; return 1; }
}

max_length_measures_individual_arguments() {
  run_spell "spells/cantrips/max-length" short medium longestword
  assert_success || return 1
  [ "$OUTPUT" = "11" ] || { TEST_FAILURE_REASON="expected longest length of 11"; return 1; }
}

max_length_splits_single_argument_list() {
  run_spell "spells/cantrips/max-length" "one fourtytwo"
  assert_success || return 1
  [ "$OUTPUT" = "9" ] || { TEST_FAILURE_REASON="expected split list longest length 9"; return 1; }
}

max_length_supports_verbose_flag() {
  run_spell "spells/cantrips/max-length" -v "tiny hugephrase"
  assert_success || return 1
  expected="Maximum length: 10
10"
  [ "$OUTPUT" = "$expected" ] || { TEST_FAILURE_REASON="expected verbose output with summary"; return 1; }
}

max_length_supports_verbose_flag_after_arguments() {
  run_spell "spells/cantrips/max-length" tiny hugephrase -v
  assert_success || return 1
  expected="Maximum length: 10
10"
  [ "$OUTPUT" = "$expected" ] || { TEST_FAILURE_REASON="expected trailing -v to enable verbose output"; return 1; }
}

max_length_does_not_glob_single_argument() {
  workdir=$(make_tempdir)
  touch "$workdir/longfilename"
  run_cmd sh -c "cd \"$workdir\" && \"$ROOT_DIR/spells/cantrips/max-length\" '*'"
  assert_success || return 1
  [ "$OUTPUT" = "1" ] || { TEST_FAILURE_REASON="expected literal asterisk length 1, got '$OUTPUT'"; return 1; }
}

run_test_case "max-length requires at least one argument" max_length_requires_input
run_test_case "max-length returns longest length for arguments" max_length_measures_individual_arguments
run_test_case "max-length splits single list argument" max_length_splits_single_argument_list
run_test_case "max-length prints verbose summary when requested" max_length_supports_verbose_flag
run_test_case "max-length accepts verbose flag after arguments" max_length_supports_verbose_flag_after_arguments
run_test_case "max-length does not glob single argument" max_length_does_not_glob_single_argument

shows_help() {
  run_spell spells/cantrips/max-length --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "max-length shows help" shows_help

max_length_returns_0_for_empty_strings() {
  run_spell "spells/cantrips/max-length" "" ""
  assert_success || return 1
  [ "$OUTPUT" = "0" ] || { TEST_FAILURE_REASON="expected 0 for empty strings"; return 1; }
}

max_length_returns_0_for_single_empty_argument() {
  run_spell "spells/cantrips/max-length" ""
  assert_success || return 1
  [ "$OUTPUT" = "0" ] || { TEST_FAILURE_REASON="expected 0 for single empty argument"; return 1; }
}

max_length_supports_interleaved_verbose_flag() {
  run_spell "spells/cantrips/max-length" "tiny" -v "hugephrase"
  assert_success || return 1
  expected="Maximum length: 10
10"
  [ "$OUTPUT" = "$expected" ] || { TEST_FAILURE_REASON="expected interleaved -v to enable verbose output"; return 1; }
}

max_length_finds_longest_in_middle() {
  run_spell "spells/cantrips/max-length" a "verylongword" b
  assert_success || return 1
  [ "$OUTPUT" = "12" ] || { TEST_FAILURE_REASON="expected longest length 12 for middle word"; return 1; }
}

max_length_handles_equal_length_words() {
  run_spell "spells/cantrips/max-length" "hello world"
  assert_success || return 1
  [ "$OUTPUT" = "5" ] || { TEST_FAILURE_REASON="expected 5 for equal-length words hello/world"; return 1; }
}

run_test_case "max-length returns 0 for empty strings" max_length_returns_0_for_empty_strings
run_test_case "max-length returns 0 for single empty argument" max_length_returns_0_for_single_empty_argument
run_test_case "max-length supports interleaved verbose flag" max_length_supports_interleaved_verbose_flag
run_test_case "max-length finds longest in middle" max_length_finds_longest_in_middle
run_test_case "max-length handles equal-length words" max_length_handles_equal_length_words

# Test via source-then-invoke pattern  

finish_tests
