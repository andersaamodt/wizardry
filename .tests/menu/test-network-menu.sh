#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/menu/network-menu" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/menu/network-menu" ]
}

shows_help() {
  run_cmd "$ROOT_DIR/spells/menu/network-menu" --help
  assert_success
  assert_output_contains "Usage: network-menu"
}

displays_available_items_when_commands_exist() {
  stubdir=$(mktemp -d "$WIZARDRY_TMPDIR/network-menu.XXXXXX")
  for name in menu colors ip nmcli ping systemctl; do
    cat >"$stubdir/$name" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"${MENU_LOG:-/tmp/menu.log}"
SH
    chmod +x "$stubdir/$name"
  done

  MENU_LOG="$stubdir/log" NETWORK_MENU_ONCE=1 PATH="$stubdir:$PATH" run_spell spells/menu/network-menu
  assert_success
  assert_file_contains "$stubdir/log" "ip link show"
  assert_file_contains "$stubdir/log" "nmcli connection show"
  assert_file_contains "$stubdir/log" "ping -c 4 1.1.1.1"
  assert_file_contains "$stubdir/log" "systemctl restart NetworkManager"
}

run_test_case "menu/network-menu is executable" spell_is_executable
run_test_case "menu/network-menu has content" spell_has_content
run_test_case "network-menu --help shows usage" shows_help
run_test_case "network-menu builds menu entries for available commands" displays_available_items_when_commands_exist

finish_tests
