#!/bin/sh
# Test assert-path-missing imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_missing_path() {
  _assert_path_missing "/nonexistent/path/to/check"
}

test_existing_path_fails() {
  tmpdir=$(_make_tempdir)
  if _assert_path_missing "$tmpdir"; then
    return 1
  fi
  return 0
}

_run_test_case "assert-path-missing succeeds on missing path" test_missing_path
_run_test_case "assert-path-missing fails on existing path" test_existing_path_fails

_finish_tests
