#!/bin/sh
# Behavioral coverage for install-best-tabby-llm spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/ai-dev/install-best-tabby-llm"

test_install_best_tabby_llm_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_install_best_tabby_llm_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_install_best_tabby_llm_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

test_install_best_tabby_llm_uses_qwen3_coder() {
  grep -F 'best_model=${TABBY_BEST_LLM_MODEL:-qwen3-coder:30b}' "$target" >/dev/null || {
    TEST_FAILURE_REASON="default best model is not qwen3-coder:30b"
    return 1
  }
}

run_test_case "install-best-tabby-llm spell exists" test_install_best_tabby_llm_exists
run_test_case "install-best-tabby-llm spell is executable" test_install_best_tabby_llm_executable
run_test_case "install-best-tabby-llm spell --help is callable" test_install_best_tabby_llm_help_callable
run_test_case "install-best-tabby-llm defaults to qwen3-coder:30b" test_install_best_tabby_llm_uses_qwen3_coder

finish_tests
