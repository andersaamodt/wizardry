#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_gazeta_menu_help() {
  run_spell "spells/.arcana/gazeta/gazeta-menu" --help
  assert_success || return 1
  assert_output_contains "Usage: gazeta-menu"
}

test_gazeta_menu_contains_install_status_uninstall_actions() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  stub-menu "$tmp"
  stub-require-command "$tmp"
  stub-exit-label "$tmp"

  run_cmd env \
    PATH="$tmp:$PATH" \
    GAZETA_DIR="$tmp/missing" \
    MENU_LOG="$tmp/menu.log" \
    MENU_LOOP_LIMIT=1 \
    "$ROOT_DIR/spells/.arcana/gazeta/gazeta-menu"
  assert_success || return 1

  args=$(cat "$tmp/menu.log" 2>/dev/null || printf '')
  case "$args" in
    *"Gazeta:"*"[ ] Gazeta%"*"/install-gazeta"*\
*"Status%"*"/gazeta-status"*\
*"Uninstall%"*"/uninstall-gazeta"*)
      ;;
    *)
      TEST_FAILURE_REASON="gazeta-menu did not expose expected actions: $args"
      return 1
      ;;
  esac
}

run_test_case "gazeta-menu shows help" test_gazeta_menu_help
run_test_case "gazeta-menu contains install/status/uninstall actions" \
  test_gazeta_menu_contains_install_status_uninstall_actions
finish_tests
