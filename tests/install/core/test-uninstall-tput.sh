#!/bin/sh
# Tests for uninstall-tput spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_uninstall_tput_is_executable() {
  [ -x "$ROOT_DIR/spells/install/core/uninstall-tput" ]
}

test_uninstall_tput_uses_manage_system_command() {
  content=$(cat "$ROOT_DIR/spells/install/core/uninstall-tput")
  case "$content" in
    *manage-system-command*--uninstall*tput*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="uninstall-tput should use manage-system-command --uninstall"
      return 1
      ;;
  esac
}

run_test_case "uninstall-tput is executable" test_uninstall_tput_is_executable
run_test_case "uninstall-tput uses manage-system-command" test_uninstall_tput_uses_manage_system_command

finish_tests
