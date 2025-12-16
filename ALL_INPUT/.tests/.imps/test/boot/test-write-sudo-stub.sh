#!/bin/sh
# Test write-sudo-stub imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  fixture=$(_make_fixture)
  _write_sudo_stub "$fixture"
  [ -x "$fixture/bin/sudo" ]
}

test_stub_runs_command() {
  fixture=$(_make_fixture)
  _write_sudo_stub "$fixture"
  output=$("$fixture/bin/sudo" echo hello)
  [ "$output" = "hello" ]
}

test_stub_strips_flags() {
  fixture=$(_make_fixture)
  _write_sudo_stub "$fixture"
  output=$("$fixture/bin/sudo" -n echo hello)
  [ "$output" = "hello" ]
}

_run_test_case "write-sudo-stub creates executable" test_creates_stub
_run_test_case "write-sudo-stub runs command" test_stub_runs_command
_run_test_case "write-sudo-stub strips sudo flags" test_stub_strips_flags

_finish_tests
