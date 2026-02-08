#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/install-ollama-daemon" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "install-ollama-daemon" || return 1
}

test_requires_ollama() {
  run_spell "spells/.arcana/ai-dev/install-ollama-daemon"
  assert_failure || return 1
  assert_error_contains "ollama" || return 1
}

run_test_case "install-ollama-daemon shows help" test_help
run_test_case "install-ollama-daemon requires ollama installed" test_requires_ollama

finish_tests
