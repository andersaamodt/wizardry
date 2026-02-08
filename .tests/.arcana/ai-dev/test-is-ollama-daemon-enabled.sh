#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/is-ollama-daemon-enabled" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
}

test_daemon_not_enabled() {
  # Should fail when daemon not enabled
  run_spell "spells/.arcana/ai-dev/is-ollama-daemon-enabled"
  assert_failure
}

run_test_case "is-ollama-daemon-enabled shows help" test_help
run_test_case "is-ollama-daemon-enabled fails when not enabled" test_daemon_not_enabled

finish_tests
