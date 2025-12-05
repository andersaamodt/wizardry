#!/bin/sh
# Tests for the 'field' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_field_with_delimiter() {
  run_cmd sh -c "printf 'a:b:c' | '$ROOT_DIR/spells/.imps/text/field' 2 ':'"
  assert_success
  assert_output_contains "b"
}

test_field_whitespace_default() {
  run_cmd sh -c "printf 'one two three' | '$ROOT_DIR/spells/.imps/text/field' 2"
  assert_success
  assert_output_contains "two"
}

run_test_case "field extracts with delimiter" test_field_with_delimiter
run_test_case "field uses whitespace default" test_field_whitespace_default

finish_tests
