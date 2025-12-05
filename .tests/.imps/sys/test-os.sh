#!/bin/sh
# Tests for the 'os' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
