#!/bin/sh
# Tests for the 'term' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_term_detects() {
  # This is tricky to test since we may or may not be in a terminal
  run_spell spells/.imps/sys/term
  # Just verify it exits without error
  [ "$STATUS" -eq 0 ] || [ "$STATUS" -eq 1 ]
}

test_term_returns_valid_status() {
  run_spell spells/.imps/sys/term
  # Status should be either 0 (in terminal) or 1 (not in terminal)
  [ "$STATUS" -eq 0 ] || [ "$STATUS" -eq 1 ] || { TEST_FAILURE_REASON="status should be 0 or 1"; return 1; }
}

run_test_case "term detects terminal" test_term_detects
run_test_case "term returns valid status" test_term_returns_valid_status

finish_tests
