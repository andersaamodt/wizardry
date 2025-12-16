#!/bin/sh
# Tests for the 'pkg-install' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pkg_install_no_package_fails() {
  skip-if-compiled || return $?
  _run_spell spells/.imps/pkg/pkg-install
  _assert_failure
  _assert_error_contains "package name required"
}

test_pkg_install_empty_package_fails() {
  skip-if-compiled || return $?
  _run_spell spells/.imps/pkg/pkg-install ""
  _assert_failure
  _assert_error_contains "package name required"
}

_run_test_case "pkg-install without package fails" test_pkg_install_no_package_fails
_run_test_case "pkg-install with empty package fails" test_pkg_install_empty_package_fails

_finish_tests
