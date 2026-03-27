#!/bin/sh
# Behavioral coverage for set-tabby-llm spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/ai-dev/set-tabby-llm"

test_set_tabby_llm_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_set_tabby_llm_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_set_tabby_llm_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "set-tabby-llm spell exists" test_set_tabby_llm_exists
run_test_case "set-tabby-llm spell is executable" test_set_tabby_llm_executable
run_test_case "set-tabby-llm spell --help is callable" test_set_tabby_llm_help_callable

finish_tests
