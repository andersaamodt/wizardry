#!/bin/sh
# Test stub-temp-file imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_temp_file "$tmpdir"
  [ -x "$tmpdir/temp-file" ]
}

test_stub_creates_temp_file() {
  tmpdir=$(make_tempdir)
  stub_temp_file "$tmpdir"
  result=$("$tmpdir/temp-file" myprefix)
  [ -f "$result" ] && printf '%s\n' "$result" | grep -q "myprefix"
}

run_test_case "stub-temp-file creates executable" test_creates_stub
run_test_case "stub-temp-file creates temp files" test_stub_creates_temp_file

finish_tests
