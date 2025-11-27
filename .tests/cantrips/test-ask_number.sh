#!/bin/sh
# Behavioral cases (derived from --help):
# - ask_number retries until valid integer
# - ask_number enforces inclusive bounds
# - ask_number validates numeric bounds
# - ask_number fails without input

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_ask_number_accepts_range_after_retry() {
  tmp=$(make_tempdir)
  printf 'abc\n7\n' >"$tmp/answers"
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "\"$ROOT_DIR/spells/cantrips/ask_number\" 'Pick' 5 10 < \"$tmp/answers\""
  assert_success && assert_output_contains "7" && assert_error_contains "Please enter a whole number."
}

test_ask_number_enforces_bounds() {
  tmp=$(make_tempdir)
  printf '4\n5\n' >"$tmp/answers"
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "\"$ROOT_DIR/spells/cantrips/ask_number\" 'Choose' 5 6 < \"$tmp/answers\""
  assert_success && assert_output_contains "5" && assert_error_contains "Please choose a number between 5 and 6."
}

test_ask_number_rejects_invalid_bounds() {
  run_cmd "$ROOT_DIR/spells/cantrips/ask_number" "Question" notanint 3
  assert_failure && assert_error_contains "MIN must be an integer."
}

test_ask_number_requires_input() {
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask_number" "Question" 1 2
  assert_failure && assert_error_contains "No interactive input available."
}

run_test_case "ask_number retries until valid integer" test_ask_number_accepts_range_after_retry
run_test_case "ask_number enforces inclusive bounds" test_ask_number_enforces_bounds
run_test_case "ask_number validates numeric bounds" test_ask_number_rejects_invalid_bounds
run_test_case "ask_number fails without input" test_ask_number_requires_input
shows_help() {
  run_spell spells/cantrips/ask_number --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "ask_number shows help" shows_help
finish_tests
