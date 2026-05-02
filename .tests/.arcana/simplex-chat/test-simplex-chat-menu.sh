#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="$ROOT_DIR/spells/.arcana/simplex-chat/simplex-chat-menu"
basic_path="/usr/bin:/bin:/usr/sbin:/sbin"

spell_is_executable() {
  [ -x "$target" ]
}

run_test_case "install/simplex-chat/simplex-chat-menu is executable" spell_is_executable

write_fake_simplex_binary() {
  fake_bin=$1
  cat >"$fake_bin" <<'SHI'
#!/bin/sh
[ "${1-}" = "-h" ] && exit 0
exit 0
SHI
  chmod +x "$fake_bin"
}

menu_prompts_install_when_missing() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-exit-label "$tmp"
  MENU_LOG="$tmp/menu.log"
  run_cmd env \
    PATH="$tmp:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$basic_path" \
    HOME="$tmp/home" \
    XDG_BIN_HOME="$tmp/bin" \
    WIZARDRY_SIMPLEX_ROOT="$tmp/state/simplex" \
    MENU_LOG="$MENU_LOG" \
    "$target"
  assert_success || return 1
  entries=$(tail -n +2 "$MENU_LOG")
  case "$entries" in
    *"[ ] Install SimpleX CLI%$ROOT_DIR/spells/.arcana/simplex-chat/install-simplex-chat"* ) : ;;
    *) TEST_FAILURE_REASON="install option missing"; return 1 ;;
  esac
  case "$entries" in
    *'Exit%kill -TERM $PPID'* ) : ;;
    *) TEST_FAILURE_REASON="exit option missing"; return 1 ;;
  esac
}

run_test_case "simplex-chat-menu offers install when SimpleX CLI is missing" menu_prompts_install_when_missing

menu_surfaces_runtime_actions_when_installed() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-exit-label "$tmp"
  mkdir -p "$tmp/state/simplex/current"
  write_fake_simplex_binary "$tmp/state/simplex/current/simplex-chat"

  MENU_LOG="$tmp/menu.log"
  run_cmd env \
    PATH="$tmp:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$basic_path" \
    HOME="$tmp/home" \
    XDG_BIN_HOME="$tmp/bin" \
    WIZARDRY_SIMPLEX_ROOT="$tmp/state/simplex" \
    MENU_LOG="$MENU_LOG" \
    "$target"

  assert_success || return 1
  entries=$(tail -n +2 "$MENU_LOG")
  case "$entries" in
    *"Run SimpleX CLI%$tmp/state/simplex/current/simplex-chat"* ) : ;;
    *) TEST_FAILURE_REASON="run option missing"; return 1 ;;
  esac
  case "$entries" in
    *"Show SimpleX CLI path%$ROOT_DIR/spells/.arcana/simplex-chat/simplex-chat-status --path"* ) : ;;
    *) TEST_FAILURE_REASON="path option missing"; return 1 ;;
  esac
  case "$entries" in
    *"[X] Install SimpleX CLI%FORCE_INSTALL=1 $ROOT_DIR/spells/.arcana/simplex-chat/install-simplex-chat"* ) : ;;
    *) TEST_FAILURE_REASON="repair install option missing"; return 1 ;;
  esac
  case "$entries" in
    *"Uninstall SimpleX CLI%$ROOT_DIR/spells/.arcana/simplex-chat/uninstall-simplex-chat"* ) : ;;
    *) TEST_FAILURE_REASON="uninstall option missing"; return 1 ;;
  esac
}

run_test_case "simplex-chat-menu surfaces installed CLI actions" menu_surfaces_runtime_actions_when_installed

finish_tests
