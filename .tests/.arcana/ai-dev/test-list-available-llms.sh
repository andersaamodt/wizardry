#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/list-available-llms" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
}

test_returns_curated_list() {
  AI_DEV_MLX_SUPPORTED=0 run_spell "spells/.arcana/ai-dev/list-available-llms"
  assert_success || return 1
  assert_output_contains "qwen3-coder:30b" || return 1
  assert_output_contains "|" || return 1  # Check pipe-delimited format
}

test_includes_all_curated_models() {
  AI_DEV_MLX_SUPPORTED=0 run_spell "spells/.arcana/ai-dev/list-available-llms"
  assert_success || return 1
  assert_output_contains "qwen3-coder:30b|best coding|19.0|256" || return 1
  assert_output_contains "llama3.1:70b|best reasoning|43.0|128" || return 1
  assert_output_contains "llava:13b|best vision|8.0|8" || return 1
}

test_mlx_curated_models_include_required_coders() {
  AI_DEV_MLX_SUPPORTED=1 run_spell "spells/.arcana/ai-dev/list-available-llms" "mlx"
  assert_success || return 1
  assert_output_contains "mlx-community/Qwen3-Coder-30B-A3B-Instruct-5bit|best local coding|20.0|256" || return 1
  assert_output_contains "mlx-community/Qwen3-Coder-Next-5bit|large coding benchmark|51.0|256" || return 1
  assert_output_contains "mlx-community/Qwen3-30B-A3B-Thinking-2507-4bit|best local architecture reasoning|18.0|256" || return 1
  assert_output_contains "mlx-community/Qwen2.5-14B-Instruct-4bit|best reasoning|8.2|128" || return 1
  assert_output_contains "mlx-community/Qwen2.5-VL-7B-Instruct-4bit|best vision|4.9|32" || return 1
}

run_test_case "list-available-llms shows help" test_help
run_test_case "list-available-llms returns curated list" test_returns_curated_list
run_test_case "list-available-llms includes all curated models" test_includes_all_curated_models
run_test_case "list-available-llms includes mlx required coders and best models" test_mlx_curated_models_include_required_coders

finish_tests
