#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_get_active_runtime_defaults_to_ollama_when_mlx_unsupported() {
  AI_DEV_MLX_SUPPORTED=0 run_spell "spells/.arcana/ai-dev/get-active-llm-runtime"
  assert_success || return 1
  [ "$OUTPUT" = "ollama" ] || {
    TEST_FAILURE_REASON="expected ollama, got: $OUTPUT"
    return 1
  }
}

test_list_available_llms_for_ollama() {
  AI_DEV_MLX_SUPPORTED=0 run_spell "spells/.arcana/ai-dev/list-available-llms" "ollama"
  assert_success || return 1
  assert_output_contains "qwen3-coder:30b|best coding|19.0|256" || return 1
  assert_output_contains "llama3.1:70b|best reasoning|43.0|128" || return 1
  assert_output_contains "llava:13b|best vision|8.0|8" || return 1
}

test_list_available_llms_for_mlx() {
  AI_DEV_MLX_SUPPORTED=1 run_spell "spells/.arcana/ai-dev/list-available-llms" "mlx"
  assert_success || return 1
  assert_output_contains "mlx-community/Qwen3-Coder-30B-A3B-Instruct-5bit|best local coding|20.0|256" || return 1
  assert_output_contains "mlx-community/Qwen3-Coder-Next-5bit|large coding benchmark|51.0|256" || return 1
  assert_output_contains "mlx-community/Qwen2.5-14B-Instruct-4bit|best reasoning|8.2|128" || return 1
  assert_output_contains "mlx-community/Qwen2.5-VL-7B-Instruct-4bit|best vision|4.9|32" || return 1
}

run_test_case "get-active-llm-runtime defaults to ollama when mlx unsupported" test_get_active_runtime_defaults_to_ollama_when_mlx_unsupported
run_test_case "list-available-llms returns ollama best-model set" test_list_available_llms_for_ollama
run_test_case "list-available-llms returns mlx required model set" test_list_available_llms_for_mlx

finish_tests
