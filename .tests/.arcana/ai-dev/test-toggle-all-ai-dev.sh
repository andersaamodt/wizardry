#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_toggle_all_help() {
  run_spell "spells/.arcana/ai-dev/toggle-all-ai-dev" --help
  assert_success || return 1
  assert_output_contains "Enables or disables all" || return 1
}

run_test_case "toggle-all-ai-dev shows help" test_toggle_all_help

finish_tests
