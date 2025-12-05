#!/bin/sh
# Tests for the 'else' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
