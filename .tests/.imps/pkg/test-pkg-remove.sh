#!/bin/sh
# Tests for the 'pkg-remove' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pkg_remove_no_package_fails() {
  _run_spell spells/.imps/pkg/pkg-remove
  _assert_failure
  _assert_error_contains "package name required"
}

test_pkg_remove_empty_package_fails() {
  _run_spell spells/.imps/pkg/pkg-remove ""
  _assert_failure
  _assert_error_contains "package name required"
}

_run_test_case "pkg-remove without package fails" test_pkg_remove_no_package_fails
_run_test_case "pkg-remove with empty package fails" test_pkg_remove_empty_package_fails

_finish_tests
