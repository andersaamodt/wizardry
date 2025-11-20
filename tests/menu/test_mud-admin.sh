#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - mud-admin presents admin actions to menu
# - mud-admin exits on interrupt triggered by menu stub

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

test_mud_admin_calls_menu_with_actions() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/mud-admin"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"MUD main menu:"*"Add authorized player%add-player"*"List authorized players%new-player"*"List shared rooms%list-rooms"*"Exit%kill -2"* ) : ;; 
    *) TEST_FAILURE_REASON="menu not invoked with expected actions"; return 1 ;;
  esac
  assert_output_contains "exiting"
}

run_test_case "mud-admin presents admin actions" test_mud_admin_calls_menu_with_actions
finish_tests
