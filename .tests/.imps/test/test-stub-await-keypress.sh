#!/bin/sh
# Tests for stub-await-keypress

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_stub_returns_enter() {
  run_spell spells/.imps/test/stub-await-keypress
  assert_success || return 1
  [ "$OUTPUT" = "enter" ] || { TEST_FAILURE_REASON="should output 'enter'"; return 1; }
}

test_stub_executable() {
  [ -x "$ROOT_DIR/spells/.imps/test/stub-await-keypress" ] || {
    TEST_FAILURE_REASON="stub should be executable"
    return 1
  }
}

run_test_case "stub returns enter" test_stub_returns_enter
run_test_case "stub is executable" test_stub_executable

finish_tests
