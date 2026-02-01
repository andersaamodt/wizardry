#!/bin/sh
# Test chatroom app structure and functionality

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_chatroom_app_exists() {
  [ -d "$test_root/.apps/chatroom" ]
}

test_chatroom_has_index() {
  [ -f "$test_root/.apps/chatroom/index.html" ]
}

test_chatroom_has_settings() {
  [ -f "$test_root/.apps/chatroom/settings.html" ]
}

test_chatroom_index_is_wrapper() {
  # Should be small wrapper, not full copy
  size=$(wc -c < "$test_root/.apps/chatroom/index.html")
  [ "$size" -lt 2000 ]
}

test_chatroom_index_references_demo() {
  grep -q "/pages/chat.html" "$test_root/.apps/chatroom/index.html"
}

test_chatroom_index_has_navigation() {
  grep -q "settings.html" "$test_root/.apps/chatroom/index.html"
}

test_chatroom_settings_has_ip_section() {
  grep -q "ip-address" "$test_root/.apps/chatroom/settings.html"
}

test_chatroom_settings_has_tor_section() {
  grep -q "tor-address" "$test_root/.apps/chatroom/settings.html"
}

test_chatroom_settings_has_hardcoded_commands() {
  grep -q "const commands" "$test_root/.apps/chatroom/settings.html"
}

test_chatroom_validates() {
  run_spell "spells/.imps/app/app-validate" "$test_root/.apps/chatroom"
  assert_success || return 1
}

test_chatroom_listed() {
  run_spell "spells/.wizardry/desktop/list-apps"
  assert_success || return 1
  assert_output_contains "chatroom" || return 1
}

test_chatroom_launches() {
  run_spell "spells/.wizardry/desktop/launch-app" "chatroom"
  assert_success || return 1
  assert_output_contains "App validated" || return 1
}

run_test_case "chatroom app directory exists" test_chatroom_app_exists
run_test_case "chatroom has index.html" test_chatroom_has_index
run_test_case "chatroom has settings.html" test_chatroom_has_settings
run_test_case "chatroom index is thin wrapper" test_chatroom_index_is_wrapper
run_test_case "chatroom index references demo chat" test_chatroom_index_references_demo
run_test_case "chatroom index has navigation to settings" test_chatroom_index_has_navigation
run_test_case "chatroom settings has IP section" test_chatroom_settings_has_ip_section
run_test_case "chatroom settings has Tor section" test_chatroom_settings_has_tor_section
run_test_case "chatroom settings has hardcoded commands" test_chatroom_settings_has_hardcoded_commands
run_test_case "chatroom app validates" test_chatroom_validates
run_test_case "chatroom appears in list-apps" test_chatroom_listed
run_test_case "chatroom launches successfully" test_chatroom_launches

finish_tests
