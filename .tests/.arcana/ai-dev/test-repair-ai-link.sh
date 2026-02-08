#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/repair-ai-link" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "repair-ai-link" || return 1
}

test_requires_both_components() {
  run_spell "spells/.arcana/ai-dev/repair-ai-link"
  assert_failure || return 1
  # Should fail when components not installed
}

run_test_case "repair-ai-link shows help" test_help
run_test_case "repair-ai-link requires both components" test_requires_both_components

finish_tests
