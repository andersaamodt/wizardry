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
  fixture=$(_make_fixture)
  _write_apt_stub "$fixture"
  _write_sudo_stub "$fixture"
  _provide_basic_tools "$fixture"
  _write_command_stub "$fixture/bin" dd

  # Force package manager to fail
  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 _run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 \
    "$ROOT_DIR/spells/install/core/uninstall-dd"

  _assert_failure || return 1
  _assert_error_contains "unable to uninstall dd automatically" || return 1
}

_run_test_case "uninstall-dd is executable" test_uninstall_dd_is_executable
_run_test_case "uninstall-dd uses manage-system-command" test_uninstall_dd_uses_manage_system_command
_run_test_case "uninstall-dd reports failure when package manager fails" test_uninstall_dd_reports_failure_when_package_manager_fails


shows_help() {
  _run_spell spells/install/core/uninstall-dd --help
  true
}

_run_test_case "uninstall-dd shows help" shows_help
_finish_tests
