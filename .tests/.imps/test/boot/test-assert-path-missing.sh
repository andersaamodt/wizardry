#!/bin/sh
# Test assert-path-missing imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_missing_path() {
  assert_path_missing "/nonexistent/path/to/check"
}

test_existing_path_fails() {
  tmpdir=$(make_tempdir)
  if assert_path_missing "$tmpdir"; then
    return 1
  fi
  return 0
}

run_test_case "assert-path-missing succeeds on missing path" test_missing_path
run_test_case "assert-path-missing fails on existing path" test_existing_path_fails

finish_tests
