#!/bin/sh
# Behavioral coverage for get-tabby-embedding-model spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/ai-dev/get-tabby-embedding-model"

test_get_tabby_embedding_model_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_get_tabby_embedding_model_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_get_tabby_embedding_model_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "get-tabby-embedding-model spell exists" test_get_tabby_embedding_model_exists
run_test_case "get-tabby-embedding-model spell is executable" test_get_tabby_embedding_model_executable
run_test_case "get-tabby-embedding-model spell --help is callable" test_get_tabby_embedding_model_help_callable

finish_tests
