#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/is-ai-component-installed" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
}

test_no_arg() {
  run_spell "spells/.arcana/ai-dev/is-ai-component-installed"
  assert_failure
}

test_invalid_component() {
  run_spell "spells/.arcana/ai-dev/is-ai-component-installed" "invalid-component"
  assert_failure
}

test_ollama_not_installed() {
  AI_DEV_FORCE_NONE=1 run_spell "spells/.arcana/ai-dev/is-ai-component-installed" "ollama"
  assert_failure
}

test_anythingllm_not_installed() {
  AI_DEV_FORCE_NONE=1 run_spell "spells/.arcana/ai-dev/is-ai-component-installed" "anythingllm"
  assert_failure
}

test_opencode_not_installed() {
  AI_DEV_OPENCODE_PATH=/definitely/missing/opencode \
    run_spell "spells/.arcana/ai-dev/is-ai-component-installed" "opencode"
  assert_failure
}

test_tabby_not_installed() {
  AI_DEV_FORCE_NONE=1 run_spell "spells/.arcana/ai-dev/is-ai-component-installed" "tabby"
  assert_failure
}

test_mlx_not_installed() {
  AI_DEV_FORCE_NONE=1 AI_DEV_MLX_SUPPORTED=1 run_spell "spells/.arcana/ai-dev/is-ai-component-installed" "mlx"
  assert_failure
}

run_test_case "is-ai-component-installed shows help" test_help
run_test_case "is-ai-component-installed fails with no argument" test_no_arg
run_test_case "is-ai-component-installed fails for invalid component" test_invalid_component
run_test_case "is-ai-component-installed ollama fails when not installed" test_ollama_not_installed
run_test_case "is-ai-component-installed mlx fails when not installed" test_mlx_not_installed
run_test_case "is-ai-component-installed anythingllm fails when not installed" test_anythingllm_not_installed
run_test_case "is-ai-component-installed opencode fails when not installed" test_opencode_not_installed
run_test_case "is-ai-component-installed tabby fails when not installed" test_tabby_not_installed

finish_tests
