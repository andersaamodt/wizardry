#!/bin/sh
# Test assert-file-contains imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_file_contains_string() {
  tmpfile=$(_make_tempdir)/testfile
  printf 'hello world\n' > "$tmpfile"
  _assert_file_contains "$tmpfile" "world"
}

test_file_missing_string() {
  tmpfile=$(_make_tempdir)/testfile
  printf 'hello world\n' > "$tmpfile"
  if _assert_file_contains "$tmpfile" "foobar"; then
    return 1
  fi
  return 0
}

test_file_not_found() {
  if _assert_file_contains "/nonexistent/path" "foo"; then
    return 1
  fi
  return 0
}

_run_test_case "assert-file-contains matches string in file" test_file_contains_string
_run_test_case "assert-file-contains fails when string missing" test_file_missing_string
_run_test_case "assert-file-contains fails on missing file" test_file_not_found

_finish_tests
