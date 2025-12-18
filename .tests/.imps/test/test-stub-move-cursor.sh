#!/bin/sh
# Tests for stub-move-cursor

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_stub_accepts_coordinates() {
  _run_spell spells/.imps/test/stub-move-cursor 1 1
  _assert_success || return 1
}

test_stub_no_output() {
  _run_spell spells/.imps/test/stub-move-cursor 10 20
  _assert_success || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="stub should produce no output"; return 1; }
}

_run_test_case "stub accepts coordinate arguments" test_stub_accepts_coordinates
_run_test_case "stub produces no output" test_stub_no_output

_finish_tests
