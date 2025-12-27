#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - services-menu validates required service spells
# - services-menu invokes menu with service actions and exits on escape

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -TERM "$PPID" 2>/dev/null || exit 0; exit 0
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
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" REQUIRE_LOG="$tmp/req" "$ROOT_DIR/spells/menu/services-menu"
  _assert_success && _assert_path_exists "$tmp/req"
}

test_services_menu_presents_actions() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  # Stub exit-label to return "Back" for submenu behavior
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  # Test as submenu (as it would be called from system-menu)
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/services-menu"
  _assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"Services Menu:"*"Start a service%start-service"*"Stop a service%stop-service"*"Restart a service%restart-service"*"Enable a service at boot%enable-service"*"Disable a service at boot%disable-service"*"Check service status%service-status"*"Check if a service is installed%is-service-installed"*"Remove a service%remove-service"*"Install service from template%install-service-template"*'Exit%kill -TERM $PPID' ) : ;; 
    *) TEST_FAILURE_REASON="menu actions missing: $args"; return 1 ;;
  esac
}

_run_test_case "services-menu validates dependencies" test_services_menu_checks_dependencies
_run_test_case "services-menu sends service actions to menu" test_services_menu_presents_actions

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  
  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/services-menu"
  _assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
  
}

_run_test_case "services-menu ESC/Exit behavior" test_esc_exit_behavior

test_shows_help() {
  _run_cmd "$ROOT_DIR/spells/menu/services-menu" --help
  _assert_success
  _assert_output_contains "Usage: services-menu"
}

_run_test_case "services-menu --help shows usage" test_shows_help


# Test via source-then-invoke pattern  
