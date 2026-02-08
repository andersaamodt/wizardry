#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/llm-menu" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "llm-menu" || return 1
}

test_requires_model_name() {
  run_spell "spells/.arcana/ai-dev/llm-menu"
  assert_failure || return 1
  assert_error_contains "model name required" || return 1
}

run_test_case "llm-menu shows help" test_help
run_test_case "llm-menu requires model name" test_requires_model_name

finish_tests
