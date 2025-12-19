#!/bin/sh
# Test heading-section imp

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

heading_section_outputs_section_heading() {
  _run_spell "spells/.imps/out/heading-section" "Summary"
  _assert_success || return 1
  _assert_output_contains "Summary" || return 1
  _assert_output_contains "---" || return 1
}

heading_section_formats_with_dashes() {
  _run_spell "spells/.imps/out/heading-section" "Test Results"
  _assert_success || return 1
  # Should contain "--- Test Results ---"
  _assert_output_contains "--- Test Results ---" || return 1
}

_run_test_case "heading-section outputs section heading" heading_section_outputs_section_heading
_run_test_case "heading-section formats with dashes" heading_section_formats_with_dashes

_finish_tests
