#!/bin/sh
# Tests for uninstall-dd spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

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

run_test_case "uninstall-dd is executable" test_uninstall_dd_is_executable
run_test_case "uninstall-dd uses manage-system-command" test_uninstall_dd_uses_manage_system_command

finish_tests
