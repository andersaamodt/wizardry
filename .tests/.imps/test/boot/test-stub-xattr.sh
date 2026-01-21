#!/bin/sh
# Test stub-xattr imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stubs() {
  tmpdir=$(make_tempdir)
  stub_xattr "$tmpdir"
  [ -x "$tmpdir/xattr" ] && [ -x "$tmpdir/attr" ] && \
  [ -x "$tmpdir/setfattr" ] && [ -x "$tmpdir/getfattr" ]
}

test_xattr_writes_and_reads() {
  tmpdir=$(make_tempdir)
  stub_xattr "$tmpdir"
  testfile="$tmpdir/testfile"
  : > "$testfile"
  "$tmpdir/xattr" -w mykey myvalue "$testfile"
  result=$("$tmpdir/xattr" -p mykey "$testfile")
  [ "$result" = "myvalue" ]
}

test_attr_writes_attributes() {
  tmpdir=$(make_tempdir)
  stub_xattr "$tmpdir"
  testfile="$tmpdir/testfile"
  : > "$testfile"
  "$tmpdir/attr" -s user.test -V testvalue "$testfile"
  [ -f "$testfile.attrs" ]
  grep -q "user.test=testvalue" "$testfile.attrs"
}

run_test_case "stub-xattr creates all executables" test_creates_stubs
run_test_case "stub-xattr writes and reads attributes" test_xattr_writes_and_reads
run_test_case "stub-xattr attr command works" test_attr_writes_attributes

finish_tests
