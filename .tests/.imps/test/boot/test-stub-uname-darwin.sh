#!/bin/sh
# Test stub-uname-darwin imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_uname_darwin "$tmpdir"
  [ -x "$tmpdir/uname" ]
}

test_stub_returns_darwin() {
  tmpdir=$(make_tempdir)
  stub_uname_darwin "$tmpdir"
  [ "$("$tmpdir/uname" -s)" = "Darwin" ]
  [ "$("$tmpdir/uname")" = "Darwin" ]
}

run_test_case "stub-uname-darwin creates executable" test_creates_stub
run_test_case "stub-uname-darwin returns Darwin" test_stub_returns_darwin

finish_tests
