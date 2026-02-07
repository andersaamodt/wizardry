#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_ai_dev_status_not_installed() {
  run_spell "spells/.arcana/ai-dev/ai-dev-status"
  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

test_is_ai_component_installed_ollama() {
  # Should fail when ollama not installed
  run_spell "spells/.arcana/ai-dev/is-ai-component-installed" "ollama"
  assert_failure
}

test_is_ai_component_installed_anythingllm() {
  # Should fail when AnythingLLM not installed
  run_spell "spells/.arcana/ai-dev/is-ai-component-installed" "anythingllm"
  assert_failure
}

test_is_ai_component_installed_invalid() {
  # Should fail for invalid component
  run_spell "spells/.arcana/ai-dev/is-ai-component-installed" "invalid"
  assert_failure
}

test_is_ai_component_installed_no_arg() {
  # Should fail with no argument
  run_spell "spells/.arcana/ai-dev/is-ai-component-installed"
  assert_failure
}

run_test_case "ai-dev-status shows not installed" test_ai_dev_status_not_installed
run_test_case "is-ai-component-installed ollama fails when not installed" test_is_ai_component_installed_ollama
run_test_case "is-ai-component-installed anythingllm fails when not installed" test_is_ai_component_installed_anythingllm
run_test_case "is-ai-component-installed fails for invalid component" test_is_ai_component_installed_invalid
run_test_case "is-ai-component-installed fails with no argument" test_is_ai_component_installed_no_arg

finish_tests
