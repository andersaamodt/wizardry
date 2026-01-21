#!/bin/sh
# Test stub-sudo imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_sudo "$tmpdir"
  [ -x "$tmpdir/sudo" ]
}

test_stub_executes_commands() {
  tmpdir=$(make_tempdir)
  stub_sudo "$tmpdir"
  result=$("$tmpdir/sudo" echo "hello world")
  [ "$result" = "hello world" ]
}

run_test_case "stub-sudo creates executable" test_creates_stub
run_test_case "stub-sudo executes commands directly" test_stub_executes_commands

finish_tests
