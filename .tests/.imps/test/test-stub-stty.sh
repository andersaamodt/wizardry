#!/bin/sh
# Tests for stub-stty

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_stub_accepts_flags() {
  run_spell spells/.imps/test/stub-stty -g
  assert_success || return 1
}

test_stub_no_output() {
  run_spell spells/.imps/test/stub-stty raw -echo
  assert_success || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="stub should produce no output"; return 1; }
}

run_test_case "stub accepts stty flags" test_stub_accepts_flags
run_test_case "stub produces no output" test_stub_no_output

finish_tests
