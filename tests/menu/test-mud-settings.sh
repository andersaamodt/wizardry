#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - mud-settings presents player management and install actions
# - mud-settings exits when interrupted by menu stub

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
printf 'failure\n' >&2
exit 9
SH
  chmod +x "$tmp/menu"
}

test_mud_settings_menu_actions() {
  tmp=$(make_tempdir)
  player=hero
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MUD_PLAYER="$player" MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-settings"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"MUD main menu:"*"Copy player key to clipboard%copy ~/.ssh/"*"Change Player%select-player"*"New Player%new-player"*"Install%mud-install-menu"*"Exit%kill -2"* ) : ;;
    *) TEST_FAILURE_REASON="mud settings actions missing"; return 1 ;;
  esac
}

test_mud_settings_requires_menu_helper() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  run_cmd env PATH="$tmp" MENU_LOG="$tmp/log" MUD_PLAYER=hero MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-settings"
  assert_failure
  assert_error_contains "missing dependency: menu"
}

test_mud_settings_reports_menu_failure() {
  tmp=$(make_tempdir)
  make_stub_colors "$tmp"
  make_failing_menu "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" MUD_PLAYER=hero MENU_LOOP_LIMIT=1 "$ROOT_DIR/spells/menu/mud-settings"
  assert_status 9
  assert_error_contains "menu failed with status 9"
  assert_file_contains "$tmp/log" "MUD main menu:"
}

run_test_case "mud-settings presents player actions" test_mud_settings_menu_actions
run_test_case "mud-settings fails fast when menu helper is missing" test_mud_settings_requires_menu_helper
run_test_case "mud-settings surfaces menu failures" test_mud_settings_reports_menu_failure
finish_tests
