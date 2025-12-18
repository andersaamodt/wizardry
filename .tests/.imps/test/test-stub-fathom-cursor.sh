#!/bin/sh
# Tests for stub-fathom-cursor

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_stub_returns_position() {
  _run_spell spells/.imps/test/stub-fathom-cursor
  _assert_success || return 1
  [ "$OUTPUT" = "1 1" ] || { TEST_FAILURE_REASON="should output '1 1'"; return 1; }
}

test_stub_returns_x() {
  _run_spell spells/.imps/test/stub-fathom-cursor -x
  _assert_success || return 1
  [ "$OUTPUT" = "1" ] || { TEST_FAILURE_REASON="should output '1'"; return 1; }
}

test_stub_returns_y() {
  _run_spell spells/.imps/test/stub-fathom-cursor -y
  _assert_success || return 1
  [ "$OUTPUT" = "1" ] || { TEST_FAILURE_REASON="should output '1'"; return 1; }
}

_run_test_case "stub returns cursor position" test_stub_returns_position
_run_test_case "stub returns x coordinate" test_stub_returns_x
_run_test_case "stub returns y coordinate" test_stub_returns_y

_finish_tests
