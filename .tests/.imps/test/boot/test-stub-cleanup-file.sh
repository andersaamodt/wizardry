#!/bin/sh
# Test stub-cleanup-file imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_cleanup_file "$tmpdir"
  [ -x "$tmpdir/cleanup-file" ]
}

test_stub_removes_file() {
  tmpdir=$(make_tempdir)
  stub_cleanup_file "$tmpdir"
  testfile="$tmpdir/testfile"
  : > "$testfile"
  "$tmpdir/cleanup-file" "$testfile"
  [ ! -f "$testfile" ]
}

run_test_case "stub-cleanup-file creates executable" test_creates_stub
run_test_case "stub-cleanup-file removes files" test_stub_removes_file

finish_tests
