#!/bin/sh
set -eu

# Locate test helpers
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/simplex-chat/simplex-chat-menu" ]
}

_run_test_case "install/simplex-chat/simplex-chat-menu is executable" spell_is_executable

make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SHI'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -TERM "$PPID" 2>/dev/null || exit 0
SHI
  chmod +x "$tmp/menu"
}

make_stub_exit_label() {
  tmp=$1
  cat >"$tmp/exit-label" <<'SHI'
#!/bin/sh
printf '%s' "Exit"
SHI
  chmod +x "$tmp/exit-label"
}

menu_prompts_install_when_missing() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_exit_label "$tmp"
  cat >"$tmp/simplex-chat-status" <<'SHI'
#!/bin/sh
echo "not installed"
SHI
  chmod +x "$tmp/simplex-chat-status"
  MENU_LOG="$tmp/menu.log"
  _run_cmd env PATH="$WIZARDRY_IMPS_PATH:$tmp:$ROOT_DIR/spells/cantrips" MENU_LOG="$MENU_LOG" \
    "$ROOT_DIR/spells/.arcana/simplex-chat/simplex-chat-menu"
  _assert_success || return 1
  entries=$(tail -n +2 "$MENU_LOG")
  case "$entries" in
    *"Install simplex-chat%install-simplex-chat"* ) : ;;
    *) TEST_FAILURE_REASON="install option missing"; return 1 ;;
  esac
  case "$entries" in
    *'Exit%kill -TERM $PPID'* ) : ;;
    *) TEST_FAILURE_REASON="exit option missing"; return 1 ;;
  esac
}

_run_test_case "simplex-chat-menu offers install when simplex-chat is missing" menu_prompts_install_when_missing

menu_orders_uninstall_before_exit_when_installed() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_exit_label "$tmp"

  cat >"$tmp/simplex-chat-status" <<'SHI'
#!/bin/sh
echo "installed"
SHI
  chmod +x "$tmp/simplex-chat-status"

  cat >"$tmp/simplex-chat" <<'SHI'
#!/bin/sh
exit 0
SHI
  chmod +x "$tmp/simplex-chat"

  MENU_LOG="$tmp/menu.log"
  _run_cmd env PATH="$WIZARDRY_IMPS_PATH:$tmp:$ROOT_DIR/spells/cantrips" MENU_LOG="$MENU_LOG" \
    "$ROOT_DIR/spells/.arcana/simplex-chat/simplex-chat-menu"

  _assert_success || return 1
  entries=$(tail -n +2 "$MENU_LOG")
  last_line=$(printf '%s\n' "$entries" | tail -n 1)
  second_last=$(printf '%s\n' "$entries" | tail -n 2 | head -n 1)

  case "$second_last" in
    "Uninstall simplex-chat%uninstall-simplex-chat") : ;;
    *) TEST_FAILURE_REASON="uninstall option should be second-to-last"; return 1 ;;
  esac

  case "$last_line" in
    *'%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="exit option should be last"; return 1 ;;
  esac

  case "$entries" in
    *"Launch simplex-chat%simplex-chat"* ) : ;;
    *) TEST_FAILURE_REASON="launch option missing"; return 1 ;;
  esac
  case "$entries" in
    *"Create or rotate user key%simplex-chat keygen"* ) : ;;
    *) TEST_FAILURE_REASON="keygen option missing"; return 1 ;;
  esac
}

_run_test_case "simplex-chat-menu surfaces CLI helpers and orders uninstall before exit" menu_orders_uninstall_before_exit_when_installed

_finish_tests
