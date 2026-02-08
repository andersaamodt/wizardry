#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/uninstall-ollama-daemon" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "uninstall-ollama-daemon" || return 1
}

test_handles_not_installed() {
  # Should succeed even if daemon config not installed
  run_spell "spells/.arcana/ai-dev/uninstall-ollama-daemon"
  assert_success || return 1
}

run_test_case "uninstall-ollama-daemon shows help" test_help
run_test_case "uninstall-ollama-daemon handles not installed" test_handles_not_installed

finish_tests
