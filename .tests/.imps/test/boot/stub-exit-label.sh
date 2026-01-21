#!/bin/sh
# Test stub-exit-label imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_exit_label "$tmpdir"
  [ -x "$tmpdir/exit-label" ]
}

test_stub_returns_exit() {
  tmpdir=$(make_tempdir)
  stub_exit_label "$tmpdir"
  result=$("$tmpdir/exit-label")
  [ "$result" = "Exit" ]
}

run_test_case "stub-exit-label creates executable" test_creates_stub
run_test_case "stub-exit-label returns Exit" test_stub_returns_exit

finish_tests
