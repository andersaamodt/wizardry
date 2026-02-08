#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/list-installed-llms" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
}

test_handles_no_ollama() {
  # Should succeed with no output when ollama not installed
  run_spell "spells/.arcana/ai-dev/list-installed-llms"
  assert_success || return 1
}

run_test_case "list-installed-llms shows help" test_help
run_test_case "list-installed-llms handles no ollama" test_handles_no_ollama

finish_tests
