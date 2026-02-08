#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/is-ollama-daemon-running" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
}

test_daemon_not_running() {
  # Should fail when daemon not running
  run_spell "spells/.arcana/ai-dev/is-ollama-daemon-running"
  assert_failure
}

run_test_case "is-ollama-daemon-running shows help" test_help
run_test_case "is-ollama-daemon-running fails when not running" test_daemon_not_running

finish_tests
