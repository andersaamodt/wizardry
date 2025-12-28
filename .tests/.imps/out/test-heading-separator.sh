#!/bin/sh
# Test heading-separator imp

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

heading_separator_outputs_centered_separator() {
  run_spell "spells/.imps/out/heading-separator" "filename.txt"
  assert_success || return 1
  assert_output_contains "filename.txt" || return 1
  assert_output_contains "#" || return 1
  assert_output_contains "-" || return 1
}

heading_separator_respects_width() {
  run_spell "spells/.imps/out/heading-separator" "test" "40"
  assert_success || return 1
  # Output should be roughly 40 characters wide
  length=$(printf '%s' "$OUTPUT" | wc -c)
  [ "$length" -ge 38 ] && [ "$length" -le 42 ] || { TEST_FAILURE_REASON="length $length not near 40"; return 1; }
}

heading_separator_accepts_custom_prefix() {
  run_spell "spells/.imps/out/heading-separator" "test" "40" "==="
  assert_success || return 1
  assert_output_contains "===" || return 1
}

run_test_case "heading-separator outputs centered separator" heading_separator_outputs_centered_separator
run_test_case "heading-separator respects width parameter" heading_separator_respects_width
run_test_case "heading-separator accepts custom prefix" heading_separator_accepts_custom_prefix

finish_tests
