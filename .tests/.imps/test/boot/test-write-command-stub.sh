#!/bin/sh
# Test write-command-stub imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(_make_tempdir)
  _write_command_stub "$tmpdir" mytool
  [ -x "$tmpdir/mytool" ]
}

test_stub_exits_zero() {
  tmpdir=$(_make_tempdir)
  _write_command_stub "$tmpdir" mytool
  "$tmpdir/mytool"
}

_run_test_case "write-command-stub creates executable" test_creates_stub
_run_test_case "write-command-stub exits zero" test_stub_exits_zero

_finish_tests
