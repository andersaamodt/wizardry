#!/bin/sh
# Tests for toggle-cd spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_toggle_cd_is_executable() {
  [ -x "$ROOT_DIR/spells/install/mud/toggle-cd" ]
}

test_toggle_cd_requires_cd_spell() {
  content=$(cat "$ROOT_DIR/spells/install/mud/toggle-cd")
  case "$content" in
    *CD_SPELL*cd*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="toggle-cd should reference the cd spell"
      return 1
      ;;
  esac
}

test_toggle_cd_has_install_and_uninstall() {
  content=$(cat "$ROOT_DIR/spells/install/mud/toggle-cd")
  case "$content" in
    *install*uninstall*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="toggle-cd should handle both install and uninstall"
      return 1
      ;;
  esac
}

run_test_case "toggle-cd is executable" test_toggle_cd_is_executable
run_test_case "toggle-cd requires cd spell" test_toggle_cd_requires_cd_spell
run_test_case "toggle-cd handles install and uninstall" test_toggle_cd_has_install_and_uninstall

finish_tests
