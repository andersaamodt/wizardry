#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - mud-admin presents admin actions to menu
# - mud-admin exits on interrupt triggered by menu stub

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

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
printf 'oops\n' >&2
exit 7
SH
  chmod +x "$tmp/menu"
}

test_mud_admin_calls_menu_with_actions() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-admin"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"MUD main menu:"*"Add authorized player%add-player"*"List authorized players%new-player"*"List shared rooms%list-rooms"*"Exit%kill -2"* ) : ;;
    *) TEST_FAILURE_REASON="menu not invoked with expected actions"; return 1 ;;
  esac
}

test_mud_admin_requires_menu_helper() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  run_cmd env PATH="$tmp" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-admin"
  assert_failure
  assert_error_contains "missing dependency: menu"
}

test_mud_admin_reports_menu_failure() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  make_failing_menu "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-admin"
  assert_status 7
  assert_error_contains "menu failed with status 7"
  assert_file_contains "$tmp/log" "MUD main menu:"
}

run_test_case "mud-admin presents admin actions" test_mud_admin_calls_menu_with_actions
run_test_case "mud-admin fails fast when menu helper is missing" test_mud_admin_requires_menu_helper
run_test_case "mud-admin surfaces menu failures" test_mud_admin_reports_menu_failure
finish_tests
