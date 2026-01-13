#!/bin/sh
# Test assert-path-exists imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_existing_path() {
  tmpdir=$(make_tempdir)
  assert_path_exists "$tmpdir"
}

test_missing_path() {
  if assert_path_exists "/nonexistent/path/to/check"; then
    return 1
  fi
  return 0
}

run_test_case "assert-path-exists succeeds on existing path" test_existing_path
run_test_case "assert-path-exists fails on missing path" test_missing_path

finish_tests
