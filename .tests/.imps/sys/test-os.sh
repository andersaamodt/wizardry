#!/bin/sh
# Tests for the 'os' imp

. "${0%/*}/../../test-common.sh"

test_os_outputs_name() {
  run_spell spells/.imps/sys/os
  assert_success
  # Should output a non-empty OS name
  [ -n "$OUTPUT" ] || { TEST_FAILURE_REASON="should output OS name"; return 1; }
}

test_os_outputs_lowercase() {
  run_spell spells/.imps/sys/os
  assert_success
  # Extract first word of output (the OS name) - ignores any sandbox warnings
  os_name=$(printf '%s\n' "$OUTPUT" | head -1 | tr -d '[:space:]')
  # OS name should be lowercase (use explicit character list to avoid locale issues with [A-Z])
  case "$os_name" in
    *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]*) TEST_FAILURE_REASON="output should be lowercase, got: $os_name"; return 1 ;;
    *) return 0 ;;
  esac
}

run_test_case "os outputs name" test_os_outputs_name
run_test_case "os outputs lowercase" test_os_outputs_lowercase

finish_tests
