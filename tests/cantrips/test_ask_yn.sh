#!/bin/sh
# Behavioral cases (derived from --help):
# - ask_yn defaults to yes on empty reply
# - ask_yn defaults to no on empty reply
# - ask_yn reprompts after invalid answer
# - ask_yn fails when input unavailable and no default
# - ask_yn rejects invalid default

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_ask_yn_accepts_default_yes() {
  run_cmd sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask_yn\" 'Continue?' yes"
  assert_success && assert_output_contains "yes"
}

test_ask_yn_accepts_default_no() {
  run_cmd sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask_yn\" 'Proceed?' no"
  assert_status 1 && assert_output_contains "no"
}

test_ask_yn_reprompts_after_invalid_answer() {
  run_cmd sh -c "printf 'maybe\\ny\\n' | \"$ROOT_DIR/spells/cantrips/ask_yn\" 'Ready?' yes"
  assert_success && assert_output_contains "yes" && assert_error_contains "Please answer yes or no."
}

test_ask_yn_fails_without_input_or_default() {
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask_yn" "Answer me"
  assert_failure && assert_error_contains "No interactive input available."
}

test_ask_yn_rejects_bad_default() {
  run_cmd "$ROOT_DIR/spells/cantrips/ask_yn" "Question" "maybe"
  assert_failure && assert_error_contains "default must be 'yes' or 'no'."
}

run_test_case "ask_yn defaults to yes on empty reply" test_ask_yn_accepts_default_yes
run_test_case "ask_yn defaults to no on empty reply" test_ask_yn_accepts_default_no
run_test_case "ask_yn reprompts after invalid answer" test_ask_yn_reprompts_after_invalid_answer
run_test_case "ask_yn fails when input unavailable and no default" test_ask_yn_fails_without_input_or_default
run_test_case "ask_yn rejects invalid default" test_ask_yn_rejects_bad_default
finish_tests
