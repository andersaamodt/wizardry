#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/install-llm" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "install-llm" || return 1
}

test_requires_model_name() {
  run_spell "spells/.arcana/ai-dev/install-llm"
  assert_failure
}

test_requires_ollama() {
  run_spell "spells/.arcana/ai-dev/install-llm" "phi3.5:mini"
  assert_failure || return 1
  assert_error_contains "ollama" || return 1
}

run_test_case "install-llm shows help" test_help
run_test_case "install-llm requires model name" test_requires_model_name
run_test_case "install-llm requires ollama installed" test_requires_ollama

finish_tests
