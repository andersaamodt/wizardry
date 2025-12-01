#!/bin/sh
# Tests for uninstall-wl-clipboard spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_uninstall_wl_clipboard_is_executable() {
  [ -x "$ROOT_DIR/spells/install/core/uninstall-wl-clipboard" ]
}

test_uninstall_wl_clipboard_uses_manage_system_command() {
  content=$(cat "$ROOT_DIR/spells/install/core/uninstall-wl-clipboard")
  case "$content" in
    *manage-system-command*--uninstall*wl-copy*wl-clipboard*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="uninstall-wl-clipboard should use manage-system-command --uninstall"
      return 1
      ;;
  esac
}

test_uninstall_wl_clipboard_reports_failure_when_package_manager_fails() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"
  write_command_stub "$fixture/bin" wl-copy

  # Force package manager to fail
  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 \
    "$ROOT_DIR/spells/install/core/uninstall-wl-clipboard"

  assert_failure || return 1
  assert_error_contains "unable to uninstall wl-copy automatically" || return 1
}

run_test_case "uninstall-wl-clipboard is executable" test_uninstall_wl_clipboard_is_executable
run_test_case "uninstall-wl-clipboard uses manage-system-command" test_uninstall_wl_clipboard_uses_manage_system_command
run_test_case "uninstall-wl-clipboard reports failure when package manager fails" test_uninstall_wl_clipboard_reports_failure_when_package_manager_fails

finish_tests
