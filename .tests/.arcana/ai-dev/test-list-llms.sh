#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_list_available_llms() {
  run_spell "spells/.arcana/ai-dev/list-available-llms"
  assert_success || return 1
  assert_output_contains "phi3.5:mini" || return 1
}

test_list_installed_llms_no_ollama() {
  # Should succeed with no output when ollama not installed
  run_spell "spells/.arcana/ai-dev/list-installed-llms"
  assert_success || return 1
}

run_test_case "list-available-llms returns curated list" test_list_available_llms
run_test_case "list-installed-llms handles no ollama" test_list_installed_llms_no_ollama

finish_tests
