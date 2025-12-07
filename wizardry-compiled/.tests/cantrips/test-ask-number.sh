#!/bin/sh
# Behavioral cases (derived from --help):
# - ask_number retries until valid integer
# - ask_number enforces inclusive bounds
# - ask_number validates numeric bounds
# - ask_number fails without input
# - ask_number accepts boundary values
# - ask_number accepts negative numbers
# - ask_number reprompts on empty input
# - ask_number rejects non-integer MAX
# - ask_number rejects MIN greater than MAX
# - ask_number shows usage on wrong argument count
# - ask_number shows range hint in prompt

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_ask_number_accepts_range_after_retry() {
  tmp=$(_make_tempdir)
  printf 'abc\n7\n' >"$tmp/answers"
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "\"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 5 10 < \"$tmp/answers\""
  _assert_success && _assert_output_contains "7" && _assert_error_contains "Whole number expected."
}

test_ask_number_enforces_bounds() {
  tmp=$(_make_tempdir)
  printf '4\n5\n' >"$tmp/answers"
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "\"$ROOT_DIR/spells/cantrips/ask-number\" 'Choose' 5 6 < \"$tmp/answers\""
  _assert_success && _assert_output_contains "5" && _assert_error_contains "Number must be between 5 and 6."
}

test_ask_number_rejects_invalid_bounds() {
  _run_cmd "$ROOT_DIR/spells/cantrips/ask-number" "Question" notanint 3
  _assert_failure && _assert_error_contains "MIN must be an integer."
}

test_ask_number_requires_input() {
  _run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask-number" "Question" 1 2
  _assert_failure && _assert_error_contains "No interactive input available."
}

# Test accepts minimum boundary value
test_ask_number_accepts_min_boundary() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '5\\n' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 5 10"
  _assert_success && _assert_output_contains "5"
}

# Test accepts maximum boundary value
test_ask_number_accepts_max_boundary() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '10\\n' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 5 10"
  _assert_success && _assert_output_contains "10"
}

# Test rejects value above maximum
test_ask_number_rejects_above_max() {
  tmp=$(_make_tempdir)
  printf '11\n10\n' >"$tmp/answers"
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "\"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 5 10 < \"$tmp/answers\""
  _assert_success && _assert_output_contains "10" && _assert_error_contains "Number must be between 5 and 10."
}

# Test accepts negative numbers when range includes them
test_ask_number_accepts_negative() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '%s\\n' '-5' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' -10 10"
  _assert_success && _assert_output_contains "-5"
}

# Test negative range bounds work
test_ask_number_negative_bounds() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '%s\\n' '-7' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' -10 -5"
  _assert_success && _assert_output_contains "-7"
}

# Test empty input reprompts
test_ask_number_reprompts_on_empty() {
  tmp=$(_make_tempdir)
  printf '\n7\n' >"$tmp/answers"
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "\"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 5 10 < \"$tmp/answers\""
  _assert_success && _assert_output_contains "7" && _assert_error_contains "Whole number expected."
}

# Test rejects non-integer MAX
test_ask_number_rejects_invalid_max() {
  _run_cmd "$ROOT_DIR/spells/cantrips/ask-number" "Question" 1 notanint
  _assert_failure && _assert_error_contains "MAX must be an integer."
}

# Test rejects MIN greater than MAX
test_ask_number_rejects_min_gt_max() {
  _run_cmd "$ROOT_DIR/spells/cantrips/ask-number" "Question" 10 5
  _assert_failure && _assert_error_contains "MIN must be less than or equal to MAX."
}

# Test shows usage with too few arguments
test_ask_number_shows_usage_too_few() {
  _run_cmd "$ROOT_DIR/spells/cantrips/ask-number" "Question" 1
  _assert_failure && _assert_error_contains "Usage:"
}

# Test shows usage with too many arguments
test_ask_number_shows_usage_too_many() {
  _run_cmd "$ROOT_DIR/spells/cantrips/ask-number" "Question" 1 10 extra
  _assert_failure && _assert_error_contains "Usage:"
}

# Test shows usage with no arguments
test_ask_number_shows_usage_no_args() {
  _run_cmd "$ROOT_DIR/spells/cantrips/ask-number"
  _assert_failure && _assert_error_contains "Usage:"
}

# Test range hint appears in prompt
test_ask_number_shows_range_hint() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '5\\n' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 1 10"
  _assert_success && _assert_error_contains "[1-10]"
}

# Test accepts zero when in range
test_ask_number_accepts_zero() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '0\\n' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' -5 5"
  _assert_success && _assert_output_contains "0"
}

# Test equal MIN and MAX (single valid value)
test_ask_number_equal_bounds() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '5\\n' | \"$ROOT_DIR/spells/cantrips/ask-number\" 'Pick' 5 5"
  _assert_success && _assert_output_contains "5"
}

_run_test_case "ask_number retries until valid integer" test_ask_number_accepts_range_after_retry
_run_test_case "ask_number enforces inclusive bounds" test_ask_number_enforces_bounds
_run_test_case "ask_number validates numeric bounds" test_ask_number_rejects_invalid_bounds
_run_test_case "ask_number fails without input" test_ask_number_requires_input
_run_test_case "ask_number accepts minimum boundary" test_ask_number_accepts_min_boundary
_run_test_case "ask_number accepts maximum boundary" test_ask_number_accepts_max_boundary
_run_test_case "ask_number rejects above maximum" test_ask_number_rejects_above_max
_run_test_case "ask_number accepts negative numbers" test_ask_number_accepts_negative
_run_test_case "ask_number negative range bounds" test_ask_number_negative_bounds
_run_test_case "ask_number reprompts on empty input" test_ask_number_reprompts_on_empty
_run_test_case "ask_number rejects non-integer MAX" test_ask_number_rejects_invalid_max
_run_test_case "ask_number rejects MIN greater than MAX" test_ask_number_rejects_min_gt_max
_run_test_case "ask_number shows usage with too few args" test_ask_number_shows_usage_too_few
_run_test_case "ask_number shows usage with too many args" test_ask_number_shows_usage_too_many
_run_test_case "ask_number shows usage with no args" test_ask_number_shows_usage_no_args
_run_test_case "ask_number shows range hint in prompt" test_ask_number_shows_range_hint
_run_test_case "ask_number accepts zero" test_ask_number_accepts_zero
_run_test_case "ask_number equal bounds" test_ask_number_equal_bounds
_finish_tests
