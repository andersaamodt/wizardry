#!/bin/sh
# Tests for stub-cursor-blink

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_stub_accepts_on() {
  run_spell spells/.imps/test/stub-cursor-blink on
  assert_success || return 1
}

test_stub_accepts_off() {
  run_spell spells/.imps/test/stub-cursor-blink off
  assert_success || return 1
}

run_test_case "stub accepts 'on' argument" test_stub_accepts_on
run_test_case "stub accepts 'off' argument" test_stub_accepts_off

finish_tests
