#!/bin/sh
# Behavioral coverage for manage-tabby-llms spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/ai-dev/manage-tabby-llms"

test_manage_tabby_llms_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_manage_tabby_llms_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_manage_tabby_llms_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "manage-tabby-llms spell exists" test_manage_tabby_llms_exists
run_test_case "manage-tabby-llms spell is executable" test_manage_tabby_llms_executable
run_test_case "manage-tabby-llms spell --help is callable" test_manage_tabby_llms_help_callable

finish_tests
