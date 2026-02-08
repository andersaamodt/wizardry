#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/start-ollama-daemon" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "start-ollama-daemon" || return 1
}

test_requires_daemon_config() {
  run_spell "spells/.arcana/ai-dev/start-ollama-daemon"
  assert_failure || return 1
}

run_test_case "start-ollama-daemon shows help" test_help
run_test_case "start-ollama-daemon requires daemon config" test_requires_daemon_config

finish_tests
