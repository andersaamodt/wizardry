#!/bin/sh
# Behavioral coverage for is-wizardry-apps-component-installed spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/wizardry-apps/is-wizardry-apps-component-installed"

test_is_wizardry_apps_component_installed_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_is_wizardry_apps_component_installed_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_is_wizardry_apps_component_installed_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "is-wizardry-apps-component-installed spell exists" test_is_wizardry_apps_component_installed_exists
run_test_case "is-wizardry-apps-component-installed spell is executable" test_is_wizardry_apps_component_installed_executable
run_test_case "is-wizardry-apps-component-installed spell --help is callable" test_is_wizardry_apps_component_installed_help_callable

finish_tests
