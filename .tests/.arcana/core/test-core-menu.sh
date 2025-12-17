#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/core/core-menu" ]
}

core_menu_lists_dependencies() {
  tmp=$(_make_tempdir)

  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"$MENU_LOG"
SH
  chmod +x "$tmp/menu"

  cat >"$tmp/colors" <<'SH'
#!/bin/sh
BOLD=''
CYAN=''
RESET=''
SH
  chmod +x "$tmp/colors"

  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
echo "$@" >>"${REQUIRE_LOG:?}"
exit 0
SH
  chmod +x "$tmp/require-command"

  ln -s /bin/sh "$tmp/sh"
  ln -s /usr/bin/dirname "$tmp/dirname"
  ln -s /bin/grep "$tmp/grep"
  ln -s /bin/cat "$tmp/cat"

  MENU_LOG="$tmp/log" _run_cmd env PATH="$WIZARDRY_IMPS_PATH:$tmp:/bin:/usr/bin" MENU_LOOP_LIMIT=1 MENU_LOG="$tmp/log" COLORS_BIN="$tmp/colors" MENU_BIN="$tmp/menu" \
    "$ROOT_DIR/spells/.arcana/core/core-menu"

  _assert_success || return 1
  _assert_path_exists "$tmp/log" || return 1
  log=$(cat "$tmp/log")

  platform=$(uname -s 2>/dev/null || printf 'unknown')
  case "$platform" in
    Darwin)
      case "$log" in
        *"Install Bubblewrap"* ) TEST_FAILURE_REASON="bubblewrap should be skipped on Darwin"; return 1 ;;
        *) : ;;
      esac
      ;;
    *)
      case "$log" in
        *"Install Bubblewrap"* ) : ;;
        *) TEST_FAILURE_REASON="missing bubblewrap entry"; return 1 ;;
      esac
      ;;
  esac

  case "$log" in
    *"Install all"* ) : ;;
    *) TEST_FAILURE_REASON="missing install all entry"; return 1 ;;
  esac
}

essential_commands_show_status_not_uninstall() {
  tmp=$(_make_tempdir)

  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"$MENU_LOG"
SH
  chmod +x "$tmp/menu"

  cat >"$tmp/colors" <<'SH'
#!/bin/sh
BOLD=''
CYAN=''
RESET=''
SH
  chmod +x "$tmp/colors"

  ln -s /bin/sh "$tmp/sh"
  ln -s /usr/bin/dirname "$tmp/dirname"
  ln -s /bin/grep "$tmp/grep"
  ln -s /bin/cat "$tmp/cat"

  # dd, stty, tput are essential and should show "- installed" or "- not installed"
  # instead of "Uninstall dd"
  MENU_LOG="$tmp/log" _run_cmd env PATH="$WIZARDRY_IMPS_PATH:$tmp:/bin:/usr/bin" MENU_LOOP_LIMIT=1 MENU_LOG="$tmp/log" COLORS_BIN="$tmp/colors" MENU_BIN="$tmp/menu" \
    "$ROOT_DIR/spells/.arcana/core/core-menu"

  _assert_success || return 1
  _assert_path_exists "$tmp/log" || return 1
  log=$(cat "$tmp/log")

  # Essential commands should NOT have "Uninstall" option
  case "$log" in
    *"Uninstall dd"* ) TEST_FAILURE_REASON="dd should not have Uninstall option"; return 1 ;;
    *) : ;;
  esac
  case "$log" in
    *"Uninstall stty"* ) TEST_FAILURE_REASON="stty should not have Uninstall option"; return 1 ;;
    *) : ;;
  esac
  case "$log" in
    *"Uninstall tput"* ) TEST_FAILURE_REASON="tput should not have Uninstall option"; return 1 ;;
    *) : ;;
  esac

  # Essential commands should show status with " - installed" or " - not installed"
  # dd is typically installed on all systems
  case "$log" in
    *"dd - installed"*|*"dd - not installed"* ) : ;;
    *) TEST_FAILURE_REASON="dd should show '- installed' or '- not installed' status"; return 1 ;;
  esac

  # stty is typically installed on all systems
  case "$log" in
    *"stty - installed"*|*"stty - not installed"* ) : ;;
    *) TEST_FAILURE_REASON="stty should show '- installed' or '- not installed' status"; return 1 ;;
  esac

  # tput is typically installed on all systems
  case "$log" in
    *"tput - installed"*|*"tput - not installed"* ) : ;;
    *) TEST_FAILURE_REASON="tput should show '- installed' or '- not installed' status"; return 1 ;;
  esac
}

_run_test_case "install/core/core-menu is executable" spell_is_executable
_run_test_case "core menu lists install targets" core_menu_lists_dependencies
_run_test_case "essential commands show status not uninstall" essential_commands_show_status_not_uninstall

test_shows_help() {
  _run_cmd "$ROOT_DIR/spells/.arcana/core/core-menu" --help
  _assert_success
  _assert_output_contains "Usage: core-menu"
}

_run_test_case "core-menu --help shows usage" test_shows_help

_finish_tests
