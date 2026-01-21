#!/bin/sh
# Test stub-status imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_status "$tmpdir" "running"
  [ -x "$tmpdir/bitcoin-status" ]
}

test_stub_returns_status() {
  tmpdir=$(make_tempdir)
  stub_status "$tmpdir" "stopped"
  result=$("$tmpdir/bitcoin-status")
  [ "$result" = "stopped" ]
}

run_test_case "stub-status creates executable" test_creates_stub
run_test_case "stub-status returns fixed status" test_stub_returns_status

finish_tests
