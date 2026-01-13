#!/bin/sh
# Test write-command-stub imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  write_command_stub "$tmpdir" mytool
  [ -x "$tmpdir/mytool" ]
}

test_stub_exits_zero() {
  tmpdir=$(make_tempdir)
  write_command_stub "$tmpdir" mytool
  "$tmpdir/mytool"
}

run_test_case "write-command-stub creates executable" test_creates_stub
run_test_case "write-command-stub exits zero" test_stub_exits_zero

finish_tests
