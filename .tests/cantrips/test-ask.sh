#!/bin/sh
# COMPILED_UNSUPPORTED: requires interactive input
# Behavioral cases (derived from --help):
# - ask relays prompts to ask_text
# - ask passes arguments to ask_text
# - ask uses default when provided
# - ask fails without default when no input available

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

ask_relays_to_ask_text() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'guildmaster\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Handle?'"
  _assert_success && _assert_output_contains "guildmaster"
}

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/cantrips/ask" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/cantrips/ask" ]
}

# Test that ask passes default argument to ask_text
test_ask_passes_default() {
  _run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask" "Color?" "green"
  _assert_success && _assert_output_contains "green"
}

# Test ask uses default on empty input
test_ask_default_on_empty() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf '\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Name?' 'anonymous'"
  _assert_success && _assert_output_contains "anonymous"
}

# Test ask fails without default and no input
test_ask_fails_without_default() {
  _run_cmd env ASK_CANTRIP_INPUT=none "$ROOT_DIR/spells/cantrips/ask" "Required?"
  _assert_failure && _assert_error_contains "No interactive input available."
}

# Test ask returns user input when provided
test_ask_returns_user_input() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'myinput\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Enter:'"
  _assert_success && _assert_output_contains "myinput"
}

# Test ask preserves input with default ignored
test_ask_user_overrides_default() {
  _run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'override\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Name?' 'default'"
  _assert_success && _assert_output_contains "override"
}

# Test --help - ask shim does not directly handle help, it delegates to ask_text
# ask_text reads it as a question argument, which is the intended simple shim behavior
test_ask_help_behavior() {
  # ask now shows help when --help is passed
  _run_cmd "$ROOT_DIR/spells/cantrips/ask" "--help"
  _assert_success && _assert_output_contains "Usage:"
}

_run_test_case "ask relays prompts to ask_text" ask_relays_to_ask_text
_run_test_case "cantrips/ask is executable" spell_is_executable
_run_test_case "cantrips/ask has content" spell_has_content
_run_test_case "ask passes default to ask_text" test_ask_passes_default
_run_test_case "ask uses default on empty input" test_ask_default_on_empty
_run_test_case "ask fails without default and no input" test_ask_fails_without_default
_run_test_case "ask returns user input" test_ask_returns_user_input
_run_test_case "ask user input overrides default" test_ask_user_overrides_default
_run_test_case "ask --help behavior (delegates to ask_text)" test_ask_help_behavior

# Test via source-then-invoke pattern  
ask_help_via_sourcing() {
  _run_sourced_spell ask --help
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

_run_test_case "ask works via source-then-invoke" ask_help_via_sourcing
_finish_tests
