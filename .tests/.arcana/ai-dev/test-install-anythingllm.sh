#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/install-anythingllm" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "install-anythingllm" || return 1
}

test_shows_manual_install_message() {
  # Currently directs to manual installation
  run_spell "spells/.arcana/ai-dev/install-anythingllm"
  assert_failure || return 1
  assert_error_contains "manual installation required" || return 1
}

run_test_case "install-anythingllm shows help" test_help
run_test_case "install-anythingllm shows manual install message" test_shows_manual_install_message

finish_tests
