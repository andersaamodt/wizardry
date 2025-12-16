#!/bin/sh
# Tests for the 'os' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_os_outputs_name() {
  _run_spell spells/.imps/sys/os
  _assert_success
  # Should output a non-empty OS name
  [ -n "$OUTPUT" ] || { TEST_FAILURE_REASON="should output OS name"; return 1; }
}

test_os_outputs_lowercase() {
  _run_spell spells/.imps/sys/os
  _assert_success
  # Extract first word of output (the OS name) - ignores any sandbox warnings
  os_name=$(printf '%s\n' "$OUTPUT" | head -1 | tr -d '[:space:]')
  # OS name should be lowercase (use explicit character list to avoid locale issues with [A-Z])
  case "$os_name" in
    *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]*) TEST_FAILURE_REASON="output should be lowercase, got: $os_name"; return 1 ;;
    *) return 0 ;;
  esac
}

_run_test_case "os outputs name" test_os_outputs_name
_run_test_case "os outputs lowercase" test_os_outputs_lowercase

_finish_tests
