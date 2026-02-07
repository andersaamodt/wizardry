#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_is_ollama_daemon_running_no_daemon() {
  # Should fail when daemon not running
  run_spell "spells/.arcana/ai-dev/is-ollama-daemon-running"
  assert_failure
}

test_is_ollama_daemon_enabled_no_daemon() {
  # Should fail when daemon not enabled
  run_spell "spells/.arcana/ai-dev/is-ollama-daemon-enabled"
  assert_failure
}

run_test_case "is-ollama-daemon-running fails when not running" test_is_ollama_daemon_running_no_daemon
run_test_case "is-ollama-daemon-enabled fails when not enabled" test_is_ollama_daemon_enabled_no_daemon

finish_tests
