#!/bin/sh
# Tests for uninstall-dd spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_uninstall_dd_is_executable() {
  [ -x "$ROOT_DIR/spells/install/core/uninstall-dd" ]
}

test_uninstall_dd_uses_manage_system_command() {
  content=$(cat "$ROOT_DIR/spells/install/core/uninstall-dd")
  case "$content" in
    *manage-system-command*--uninstall*dd*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="uninstall-dd should use manage-system-command --uninstall"
      return 1
      ;;
  esac
}

test_uninstall_dd_reports_failure_when_package_manager_fails() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"
  write_command_stub "$fixture/bin" dd

  # Force package manager to fail
  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 \
    "$ROOT_DIR/spells/install/core/uninstall-dd"

  assert_failure || return 1
  assert_error_contains "unable to uninstall dd automatically" || return 1
}

run_test_case "uninstall-dd is executable" test_uninstall_dd_is_executable
run_test_case "uninstall-dd uses manage-system-command" test_uninstall_dd_uses_manage_system_command
run_test_case "uninstall-dd reports failure when package manager fails" test_uninstall_dd_reports_failure_when_package_manager_fails


shows_help() {
  run_spell spells/install/core/uninstall-dd --help
  true
}

run_test_case "uninstall-dd shows help" shows_help
finish_tests
