#!/bin/sh
# Behavioral cases (derived from --help):
# - ask relays prompts to ask_text

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

ask_relays_to_ask_text() {
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'guildmaster\\n' | \"$ROOT_DIR/spells/cantrips/ask\" 'Handle?'"
  assert_success && assert_output_contains "guildmaster"
}

run_test_case "ask relays prompts to ask_text" ask_relays_to_ask_text
finish_tests
