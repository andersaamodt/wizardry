#!/bin/sh
# Behavioral cases (derived from --help):
# - ask_text reads piped input
# - ask_text uses default when input missing
# - ask_text fails without default when input unavailable
# - ask shim relays to ask_text
# - ask_text returns empty input when no default
# - ask_text uses default on empty input
# - ask_text preserves whitespace in input
# - ask_text shows default hint in prompt
# - ask_text shows usage on too few arguments
# - ask_text shows usage on too many arguments

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_ask_text_reads_stdin() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'hello\\n' | \"$ROOT_DIR/spells/cantrips/ask-text\" 'Your name?'"
  _assert_success && _assert_output_contains "hello"
}

test_ask_text_uses_default_without_input() {
  _run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask-text" "Favorite color?" "blue"
  _assert_success && _assert_output_contains "blue"
}

test_ask_text_fails_without_default_or_input() {
  _run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask-text" "Favorite color?"
  _assert_failure && _assert_error_contains "No interactive input available."
}

test_ask_delegates_to_ask_text() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'wizard\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Call sign?'"
  _assert_success && _assert_output_contains "wizard"
}

# Test empty input returns empty string when no default
test_ask_text_empty_input_no_default() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask-text\" 'Enter value?'"
  _assert_success
  # Output should be empty (just a newline)
  case "$OUTPUT" in
    '') : ;;
    *) TEST_FAILURE_REASON="expected empty output but got: $OUTPUT"; return 1 ;;
  esac
}

# Test empty input uses default when default is provided
test_ask_text_empty_input_uses_default() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask-text\" 'Enter value?' 'mydefault'"
  _assert_success && _assert_output_contains "mydefault"
}

# Test whitespace is preserved in input
test_ask_text_preserves_whitespace() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '  spaces  \\n' | \"$ROOT_DIR/spells/cantrips/ask-text\" 'Enter text?'"
  _assert_success
  case "$OUTPUT" in
    *"  spaces  "*) : ;;
    *) TEST_FAILURE_REASON="expected whitespace preserved but got: $OUTPUT"; return 1 ;;
  esac
}

# Test default hint appears in prompt
test_ask_text_shows_default_hint() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'value\\n' | \"$ROOT_DIR/spells/cantrips/ask-text\" 'Question?' 'default_val'"
  _assert_success && _assert_error_contains "[default_val]"
}

# Test no default hint when no default provided
test_ask_text_no_hint_without_default() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'value\\n' | \"$ROOT_DIR/spells/cantrips/ask-text\" 'Question?'"
  _assert_success
  case "$ERROR" in
    *"["*) TEST_FAILURE_REASON="unexpected default hint in prompt: $ERROR"; return 1 ;;
    *) : ;;
  esac
}

# Test usage error with no arguments
test_ask_text_shows_usage_no_args() {
  _run_cmd "$ROOT_DIR/spells/cantrips/ask-text"
  _assert_failure && _assert_error_contains "Usage:"
}

# Test usage error with too many arguments
test_ask_text_shows_usage_too_many_args() {
  _run_cmd "$ROOT_DIR/spells/cantrips/ask-text" "Question?" "default" "extra"
  _assert_failure && _assert_error_contains "Usage:"
}

# Test input with special characters
test_ask_text_handles_special_chars() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'hello!@#\$%%^&*()\\n' | \"$ROOT_DIR/spells/cantrips/ask-text\" 'Enter text?'"
  _assert_success && _assert_output_contains "hello"
}

# Test default with special characters
test_ask_text_default_with_spaces() {
  _run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask-text" "Question?" "default with spaces"
  _assert_success && _assert_output_contains "default with spaces"
}

_run_test_case "ask_text reads piped input" test_ask_text_reads_stdin
_run_test_case "ask_text uses default when input missing" test_ask_text_uses_default_without_input
_run_test_case "ask_text fails without default when input unavailable" test_ask_text_fails_without_default_or_input
_run_test_case "ask shim relays to ask_text" test_ask_delegates_to_ask_text
_run_test_case "ask_text returns empty on empty input without default" test_ask_text_empty_input_no_default
_run_test_case "ask_text uses default on empty input" test_ask_text_empty_input_uses_default
_run_test_case "ask_text preserves whitespace in input" test_ask_text_preserves_whitespace
_run_test_case "ask_text shows default hint in prompt" test_ask_text_shows_default_hint
_run_test_case "ask_text shows no hint without default" test_ask_text_no_hint_without_default
_run_test_case "ask_text shows usage with no arguments" test_ask_text_shows_usage_no_args
_run_test_case "ask_text shows usage with too many arguments" test_ask_text_shows_usage_too_many_args
_run_test_case "ask_text handles special characters" test_ask_text_handles_special_chars
_run_test_case "ask_text default with spaces" test_ask_text_default_with_spaces
_finish_tests
