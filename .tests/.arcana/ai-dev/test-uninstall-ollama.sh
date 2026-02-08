#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/uninstall-ollama" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "uninstall-ollama" || return 1
}

test_handles_not_installed() {
  # Should succeed even if ollama not installed
  run_spell "spells/.arcana/ai-dev/uninstall-ollama"
  assert_success || return 1
}

run_test_case "uninstall-ollama shows help" test_help
run_test_case "uninstall-ollama handles not installed" test_handles_not_installed

finish_tests
