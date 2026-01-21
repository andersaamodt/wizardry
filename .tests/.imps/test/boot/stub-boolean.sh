#!/bin/sh
# Test stub-boolean imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_boolean "$tmpdir/test-cmd" 0
  [ -x "$tmpdir/test-cmd" ]
}

test_stub_exits_with_code() {
  tmpdir=$(make_tempdir)
  stub_boolean "$tmpdir/success" 0
  stub_boolean "$tmpdir/failure" 1
  "$tmpdir/success" && ! "$tmpdir/failure"
}

run_test_case "stub-boolean creates executable" test_creates_stub
run_test_case "stub-boolean exits with specified code" test_stub_exits_with_code

finish_tests
