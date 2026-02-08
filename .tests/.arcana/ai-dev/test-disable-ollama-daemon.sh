#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/disable-ollama-daemon" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "disable-ollama-daemon" || return 1
}

test_handles_not_enabled() {
  # Should succeed even if daemon not enabled
  run_spell "spells/.arcana/ai-dev/disable-ollama-daemon"
  assert_success || return 1
}

run_test_case "disable-ollama-daemon shows help" test_help
run_test_case "disable-ollama-daemon handles not enabled" test_handles_not_enabled

finish_tests
