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
  run_spell "spells/.arcana/ai-dev/list-available-llms"
  assert_success || return 1
  assert_output_contains "phi3:mini" || return 1
  assert_output_contains "|" || return 1  # Check pipe-delimited format
}

test_includes_all_curated_models() {
  run_spell "spells/.arcana/ai-dev/list-available-llms"
  assert_success || return 1
  assert_output_contains "qwen3-coder:30b|agentic code and system design|19.0|256" || return 1
}

test_excludes_superseded_qwen_models() {
  run_spell "spells/.arcana/ai-dev/list-available-llms"
  assert_success || return 1
  case "$OUTPUT" in
    *qwen3.5:9b*|*qwen2.5-coder:7b*)
      TEST_FAILURE_REASON="superseded Qwen model remains in curated list"
      return 1
      ;;
  esac
}

run_test_case "list-available-llms shows help" test_help
run_test_case "list-available-llms returns curated list" test_returns_curated_list
run_test_case "list-available-llms includes all curated models" test_includes_all_curated_models
run_test_case "list-available-llms excludes superseded Qwen models" test_excludes_superseded_qwen_models

finish_tests
