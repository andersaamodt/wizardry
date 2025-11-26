#!/bin/sh
# Behavioral cases (derived from --help):
# - ask relays prompts to ask_text

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

run_test_case "ask relays prompts to ask_text" ask_relays_to_ask_text
run_test_case "cantrips/ask is executable" spell_is_executable
run_test_case "cantrips/ask has content" spell_has_content
finish_tests
