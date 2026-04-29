#!/bin/sh
# Test stub-uname-linux imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_uname_linux "$tmpdir"
  [ -x "$tmpdir/uname" ]
}

test_stub_returns_linux() {
  tmpdir=$(make_tempdir)
  stub_uname_linux "$tmpdir"
  [ "$("$tmpdir/uname" -s)" = "Linux" ]
  [ "$("$tmpdir/uname")" = "Linux" ]
}

run_test_case "stub-uname-linux creates executable" test_creates_stub
run_test_case "stub-uname-linux returns Linux" test_stub_returns_linux

finish_tests
