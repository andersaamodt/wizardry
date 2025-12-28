#!/bin/sh
# Tests for stub-fathom-terminal

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_stub_returns_dimensions() {
  run_spell spells/.imps/test/stub-fathom-terminal
  assert_success || return 1
  [ "$OUTPUT" = "80 24" ] || { TEST_FAILURE_REASON="should output '80 24'"; return 1; }
}

test_stub_returns_height() {
  run_spell spells/.imps/test/stub-fathom-terminal --height
  assert_success || return 1
  [ "$OUTPUT" = "24" ] || { TEST_FAILURE_REASON="should output '24'"; return 1; }
}

test_stub_returns_width() {
  run_spell spells/.imps/test/stub-fathom-terminal --width
  assert_success || return 1
  [ "$OUTPUT" = "80" ] || { TEST_FAILURE_REASON="should output '80'"; return 1; }
}

run_test_case "stub returns terminal dimensions" test_stub_returns_dimensions
run_test_case "stub returns terminal height" test_stub_returns_height
run_test_case "stub returns terminal width" test_stub_returns_width

finish_tests
