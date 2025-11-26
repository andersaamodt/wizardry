#!/bin/sh
# Tests for the 'else' imp

. "${0%/*}/../test-common.sh"

test_else_uses_default() {
  run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/else' 'fallback'"
  assert_success
  assert_output_contains "fallback"
}

test_else_passes_through() {
  run_cmd sh -c "printf 'original' | '$ROOT_DIR/spells/.imps/else' 'fallback'"
  assert_success
  assert_output_contains "original"
}

run_test_case "else uses default for empty" test_else_uses_default
run_test_case "else passes through non-empty" test_else_passes_through

finish_tests
