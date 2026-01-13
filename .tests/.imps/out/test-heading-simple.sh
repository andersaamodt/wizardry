#!/bin/sh
# Test heading-simple imp

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

heading_simple_outputs_text() {
  run_spell "spells/.imps/out/heading-simple" "Installation"
  assert_success || return 1
  assert_output_contains "Installation" || return 1
}

heading_simple_accepts_prefix() {
  run_spell "spells/.imps/out/heading-simple" "Step 1" "==>"
  assert_success || return 1
  assert_output_contains "==>" || return 1
  assert_output_contains "Step 1" || return 1
}

run_test_case "heading-simple outputs text" heading_simple_outputs_text
run_test_case "heading-simple accepts prefix" heading_simple_accepts_prefix

finish_tests
