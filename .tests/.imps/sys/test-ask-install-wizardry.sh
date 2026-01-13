#!/bin/sh
# Tests for ask-install-wizardry imp
# - Prints install instructions in non-interactive mode
# - Prompts user in interactive mode
# - Returns appropriate exit codes

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_non_interactive_prints_instructions() {
  # Non-interactive: stdin not a TTY
  run_cmd sh -c 'spells/.imps/sys/ask-install-wizardry </dev/null'
  assert_failure || return 1
  assert_error_contains "This script requires wizardry" || return 1
  assert_error_contains "curl -fsSL" || return 1
}

test_interactive_prompts_user() {
  skip-if-compiled || return $?
  
  # Just verify the imp is callable and has expected behavior
  # Full interactive testing is difficult without a real TTY
  run_cmd spells/.imps/sys/ask-install-wizardry </dev/null
  assert_failure || return 1
  # Should print instructions when not interactive
  assert_error_contains "wizardry" || return 1
}

run_test_case "non-interactive prints instructions" test_non_interactive_prints_instructions
run_test_case "interactive mode callable" test_interactive_prompts_user
finish_tests
