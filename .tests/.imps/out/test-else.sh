#!/bin/sh
# Tests for the 'else' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_else_uses_default() {
  run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/out/else' 'fallback'"
  assert_success
  assert_output_contains "fallback"
}

test_else_passes_through() {
  run_cmd sh -c "printf 'original' | '$ROOT_DIR/spells/.imps/out/else' 'fallback'"
  assert_success
  assert_output_contains "original"
}

run_test_case "else uses default for empty" test_else_uses_default
run_test_case "else passes through non-empty" test_else_passes_through

finish_tests
