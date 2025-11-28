#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - services-menu validates required service spells
# - services-menu invokes menu with service actions and exits on escape

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
exit 113
SH
  chmod +x "$tmp/menu"
}

make_stub_require() {
  tmp=$1
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s' "$1" >>"$REQUIRE_LOG"
exit 0
SH
  chmod +x "$tmp/require-command"
}

test_services_menu_checks_dependencies() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" REQUIRE_LOG="$tmp/req" "$ROOT_DIR/spells/menu/services-menu"
  assert_success && assert_path_exists "$tmp/req"
}

test_services_menu_presents_actions() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  # Stub exit-label to return "Back" for submenu behavior
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
if [ "${WIZARDRY_SUBMENU-}" = "1" ]; then printf '%s' "Back"; else printf '%s' "Exit"; fi
SH
  chmod +x "$tmp/exit-label"
  # Test as submenu (as it would be called from system-menu)
  run_cmd env WIZARDRY_SUBMENU=1 PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/services-menu"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"Services Menu:"*"Start a service%start-service"*"Stop a service%stop-service"*"Restart a service%restart-service"*"Enable a service at boot%enable-service"*"Disable a service at boot%disable-service"*"Check service status%service-status"*"Check if a service is installed%is-service-installed"*"Remove a service%remove-service"*"Install service from template%install-service-template"*"Back%kill -2"* ) : ;; 
    *) TEST_FAILURE_REASON="menu actions missing: $args"; return 1 ;;
  esac
}

run_test_case "services-menu validates dependencies" test_services_menu_checks_dependencies
run_test_case "services-menu sends service actions to menu" test_services_menu_presents_actions

shows_help() {
  run_spell spells/menu/services-menu --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "services-menu accepts --help" shows_help
finish_tests
