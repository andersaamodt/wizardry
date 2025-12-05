#!/bin/sh
# Tests for uninstall-xclip spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_uninstall_xclip_is_executable() {
  [ -x "$ROOT_DIR/spells/install/core/uninstall-xclip" ]
}

test_uninstall_xclip_uses_manage_system_command() {
  content=$(cat "$ROOT_DIR/spells/install/core/uninstall-xclip")
  case "$content" in
    *manage-system-command*--uninstall*xclip*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="uninstall-xclip should use manage-system-command --uninstall"
      return 1
      ;;
  esac
}

test_uninstall_xclip_reports_failure_when_package_manager_fails() {
  fixture=$(_make_fixture)
  _write_apt_stub "$fixture"
  _write_sudo_stub "$fixture"
  _provide_basic_tools "$fixture"
  _write_command_stub "$fixture/bin" xclip

  # Force package manager to fail
  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 _run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 \
    "$ROOT_DIR/spells/install/core/uninstall-xclip"

  _assert_failure || return 1
  _assert_error_contains "unable to uninstall xclip automatically" || return 1
}

_run_test_case "uninstall-xclip is executable" test_uninstall_xclip_is_executable
_run_test_case "uninstall-xclip uses manage-system-command" test_uninstall_xclip_uses_manage_system_command
_run_test_case "uninstall-xclip reports failure when package manager fails" test_uninstall_xclip_reports_failure_when_package_manager_fails

shows_help() {
  _run_spell spells/install/core/uninstall-xclip --help
  true
}

_run_test_case "uninstall-xclip shows help" shows_help
_finish_tests
