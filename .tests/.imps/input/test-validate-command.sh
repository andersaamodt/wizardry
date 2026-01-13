#!/bin/sh
# Test validate-command imp

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_valid_command() {
  run_cmd validate-command "echo hello" "command"
  assert_success || return 1
}

test_rejects_empty_command() {
  run_cmd validate-command "" "command"
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"must not be empty"*) : ;;
    *) TEST_FAILURE_REASON="expected error about empty command"; return 1 ;;
  esac
}

test_rejects_tabs() {
  # Create a command with a tab character
  run_cmd sh -c 'validate-command "echo	hello" "command"'
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"may not contain tabs"*) : ;;
    *) TEST_FAILURE_REASON="expected error about tabs"; return 1 ;;
  esac
}

test_rejects_newlines() {
  run_cmd sh -c 'validate-command "echo
hello" "command"'
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"must be a single line"*) : ;;
    *) TEST_FAILURE_REASON="expected error about single line"; return 1 ;;
  esac
}

test_context_in_error() {
  run_cmd validate-command "" "spell command"
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"spell command must not be empty"*) : ;;
    *) TEST_FAILURE_REASON="expected context in error message"; return 1 ;;
  esac
}

run_test_case "validate-command accepts valid command" test_valid_command
run_test_case "validate-command rejects empty command" test_rejects_empty_command
run_test_case "validate-command rejects tabs" test_rejects_tabs
run_test_case "validate-command rejects newlines" test_rejects_newlines
run_test_case "validate-command includes context in error" test_context_in_error

finish_tests
