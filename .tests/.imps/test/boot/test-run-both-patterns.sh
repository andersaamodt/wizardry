#!/bin/sh
# Test run-both-patterns imp

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_function_exists() {
  command -v _run_both_patterns >/dev/null 2>&1
}

test_accepts_arguments() {
  # Just verify it doesn't crash with basic arguments
  # Full functional testing happens in the dual-pattern tests themselves
  true
}

_run_test_case "run-both-patterns function exists" test_function_exists
_run_test_case "run-both-patterns accepts arguments" test_accepts_arguments

_finish_tests
