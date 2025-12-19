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
  _run_spell "spells/.imps/out/heading-simple" "Installation"
  _assert_success || return 1
  _assert_output_contains "Installation" || return 1
}

heading_simple_accepts_prefix() {
  _run_spell "spells/.imps/out/heading-simple" "Step 1" "==>"
  _assert_success || return 1
  _assert_output_contains "==>" || return 1
  _assert_output_contains "Step 1" || return 1
}

_run_test_case "heading-simple outputs text" heading_simple_outputs_text
_run_test_case "heading-simple accepts prefix" heading_simple_accepts_prefix

_finish_tests
