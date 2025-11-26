#!/bin/sh
# Behavioral cases (derived from --help):
# - ask_text reads piped input
# - ask_text uses default when input missing
# - ask_text fails without default when input unavailable
# - ask shim relays to ask_text

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_ask_text_reads_stdin() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'hello\\n' | \"$ROOT_DIR/spells/cantrips/ask_text\" 'Your name?'"
  assert_success && assert_output_contains "hello"
}

test_ask_text_uses_default_without_input() {
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask_text" "Favorite color?" "blue"
  assert_success && assert_output_contains "blue"
}

test_ask_text_fails_without_default_or_input() {
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask_text" "Favorite color?"
  assert_failure && assert_error_contains "No interactive input available."
}

test_ask_delegates_to_ask_text() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'wizard\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Call sign?'"
  assert_success && assert_output_contains "wizard"
}

run_test_case "ask_text reads piped input" test_ask_text_reads_stdin
run_test_case "ask_text uses default when input missing" test_ask_text_uses_default_without_input
run_test_case "ask_text fails without default when input unavailable" test_ask_text_fails_without_default_or_input
run_test_case "ask shim relays to ask_text" test_ask_delegates_to_ask_text
finish_tests
