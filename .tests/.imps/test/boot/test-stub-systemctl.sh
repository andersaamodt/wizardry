#!/bin/sh
# Test stub-systemctl imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_systemctl "$tmpdir"
  [ -x "$tmpdir/systemctl" ]
}

test_stub_logs_args() {
  tmpdir=$(make_tempdir)
  stub_systemctl "$tmpdir"
  "$tmpdir/systemctl" enable myservice
  [ -f "$tmpdir/systemctl.args" ]
  grep -q "enable myservice" "$tmpdir/systemctl.args"
}

run_test_case "stub-systemctl creates executable" test_creates_stub
run_test_case "stub-systemctl logs arguments" test_stub_logs_args

finish_tests
