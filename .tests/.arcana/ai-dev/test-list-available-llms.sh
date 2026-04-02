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
  assert_output_contains "phi3.5:mini" || return 1
  assert_output_contains "|" || return 1  # Check pipe-delimited format
}

test_includes_all_curated_models() {
  run_spell "spells/.arcana/ai-dev/list-available-llms"
  assert_success || return 1
  assert_output_contains "starcoder2:15b" || return 1
  assert_output_contains "deepseek-coder:33b" || return 1
  assert_output_contains "llama3.1:70b" || return 1
}

run_test_case "list-available-llms shows help" test_help
run_test_case "list-available-llms returns curated list" test_returns_curated_list
run_test_case "list-available-llms includes all curated models" test_includes_all_curated_models

finish_tests
