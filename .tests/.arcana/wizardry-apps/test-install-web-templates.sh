#!/bin/sh
# Behavioral coverage for install-web-templates spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/wizardry-apps/install-web-templates"

test_install_web_templates_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_install_web_templates_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_install_web_templates_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "install-web-templates spell exists" test_install_web_templates_exists
run_test_case "install-web-templates spell is executable" test_install_web_templates_executable
run_test_case "install-web-templates spell --help is callable" test_install_web_templates_help_callable

finish_tests
