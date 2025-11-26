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

ask_fails_without_helper() {
  # ask should fail when ask_text helper is missing from path
  stub_dir=$(make_tempdir)
  run_cmd env PATH="$stub_dir" "$ROOT_DIR/spells/cantrips/ask" "test"
  assert_failure
}

run_test_case "ask relays prompts to ask_text" ask_relays_to_ask_text
run_test_case "ask fails without helper" ask_fails_without_helper
finish_tests
