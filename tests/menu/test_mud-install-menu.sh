#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - mud-install-menu offers tor setup and exits on interrupt

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

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

test_mud_install_menu_calls_tor_installer() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud-install-menu"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"MUD main menu:"*"setup-tor"*"Exit%kill -2"* ) : ;; 
    *) TEST_FAILURE_REASON="tor setup entry missing"; return 1 ;;
  esac
  assert_output_contains "exiting"
}

run_test_case "mud-install-menu invokes tor setup" test_mud_install_menu_calls_tor_installer
finish_tests
