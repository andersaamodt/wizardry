#!/bin/sh
# Behavioral cases (derived from --help):
# - ask relays prompts to ask_text
# - ask passes arguments to ask_text
# - ask uses default when provided
# - ask fails without default when no input available

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

ask_relays_to_ask_text() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'guildmaster\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Handle?'"
  assert_success && assert_output_contains "guildmaster"
}

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/cantrips/ask" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/cantrips/ask" ]
}

# Test that ask passes default argument to ask_text
test_ask_passes_default() {
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask" "Color?" "green"
  assert_success && assert_output_contains "green"
}

# Test ask uses default on empty input
test_ask_default_on_empty() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Name?' 'anonymous'"
  assert_success && assert_output_contains "anonymous"
}

# Test ask fails without default and no input
test_ask_fails_without_default() {
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask" "Required?"
  assert_failure && assert_error_contains "No interactive input available."
}

# Test ask returns user input when provided
test_ask_returns_user_input() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'myinput\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Enter:'"
  assert_success && assert_output_contains "myinput"
}

# Test ask preserves input with default ignored
test_ask_user_overrides_default() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'override\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Name?' 'default'"
  assert_success && assert_output_contains "override"
}

# Test --help - ask shim does not directly handle help, it delegates to ask_text
# ask_text reads it as a question argument, which is the intended simple shim behavior
test_ask_help_behavior() {
  # ask shim passes --help as a question to ask_text, not as a flag
  # This is intentional: ask is a simple relay that doesn't add its own options
  run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask" "--help" "default"
  assert_success && assert_output_contains "default"
}

run_test_case "ask relays prompts to ask_text" ask_relays_to_ask_text
run_test_case "cantrips/ask is executable" spell_is_executable
run_test_case "cantrips/ask has content" spell_has_content
run_test_case "ask passes default to ask_text" test_ask_passes_default
run_test_case "ask uses default on empty input" test_ask_default_on_empty
run_test_case "ask fails without default and no input" test_ask_fails_without_default
run_test_case "ask returns user input" test_ask_returns_user_input
run_test_case "ask user input overrides default" test_ask_user_overrides_default
run_test_case "ask --help behavior (delegates to ask_text)" test_ask_help_behavior
finish_tests
