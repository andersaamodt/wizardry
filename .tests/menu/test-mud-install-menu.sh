#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - mud-install-menu offers tor setup and exits on interrupt

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -s INT "$PPID"
exit 0
SH
  chmod +x "$tmp/menu"
}

make_stub_colors() {
  tmp=$1
  cat >"$tmp/colors" <<'SH'
#!/bin/sh
RESET=''
CYAN=''
GREY=''
SH
  chmod +x "$tmp/colors"
}

make_failing_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
printf 'menu busted\n' >&2
exit 5
SH
  chmod +x "$tmp/menu"
}

test_mud_install_menu_calls_tor_installer() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
command -v "$1" >/dev/null 2>&1
SH
  chmod +x "$tmp/require-command"
  # Stub exit-label to return "Back" for submenu behavior
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
if [ "${WIZARDRY_SUBMENU-}" = "1" ]; then printf '%s' "Back"; else printf '%s' "Exit"; fi
SH
  chmod +x "$tmp/exit-label"
  # Test as submenu (as it would be called from mud menu)
  # Use MENU_LOOP_LIMIT=1 to exit after one iteration
  run_cmd env WIZARDRY_SUBMENU=1 REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"MUD Install:"*"/install/tor/setup-tor"*"Back%kill -2"* ) : ;;
    *) TEST_FAILURE_REASON="tor setup entry missing: $args"; return 1 ;;
  esac
}

test_mud_install_menu_requires_menu_helper() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s\n' "The MUD Install menu needs the 'menu' command to present options." >&2
exit 1
SH
  chmod +x "$tmp/require-command"
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_failure
  assert_error_contains "The MUD Install menu needs the 'menu' command"
}

test_mud_install_menu_reports_menu_failure() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  make_failing_menu "$tmp"
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
command -v "$1" >/dev/null 2>&1
SH
  chmod +x "$tmp/require-command"
  # Stub exit-label
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env REQUIRE_COMMAND="$tmp/require-command" PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_status 5
  assert_file_contains "$tmp/log" "MUD Install:"
}

run_test_case "mud-install-menu invokes tor setup" test_mud_install_menu_calls_tor_installer
run_test_case "mud-install-menu fails fast when menu helper is missing" test_mud_install_menu_requires_menu_helper
run_test_case "mud-install-menu surfaces menu failures" test_mud_install_menu_reports_menu_failure
finish_tests
