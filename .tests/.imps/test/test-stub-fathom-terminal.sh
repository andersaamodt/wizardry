#!/bin/sh
# Tests for stub-fathom-terminal

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_stub_returns_dimensions() {
  _run_spell spells/.imps/test/stub-fathom-terminal
  _assert_success || return 1
  [ "$OUTPUT" = "80 24" ] || { TEST_FAILURE_REASON="should output '80 24'"; return 1; }
}

test_stub_returns_height() {
  _run_spell spells/.imps/test/stub-fathom-terminal --height
  _assert_success || return 1
  [ "$OUTPUT" = "24" ] || { TEST_FAILURE_REASON="should output '24'"; return 1; }
}

test_stub_returns_width() {
  _run_spell spells/.imps/test/stub-fathom-terminal --width
  _assert_success || return 1
  [ "$OUTPUT" = "80" ] || { TEST_FAILURE_REASON="should output '80'"; return 1; }
}

_run_test_case "stub returns terminal dimensions" test_stub_returns_dimensions
_run_test_case "stub returns terminal height" test_stub_returns_height
_run_test_case "stub returns terminal width" test_stub_returns_width

_finish_tests
