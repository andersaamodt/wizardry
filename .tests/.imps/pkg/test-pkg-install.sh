#!/bin/sh
# Tests for the 'pkg-install' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_pkg_install_no_package_fails() {
  run_spell spells/.imps/pkg/pkg-install
  assert_failure
  assert_error_contains "package name required"
}

test_pkg_install_empty_package_fails() {
  run_spell spells/.imps/pkg/pkg-install ""
  assert_failure
  assert_error_contains "package name required"
}

run_test_case "pkg-install without package fails" test_pkg_install_no_package_fails
run_test_case "pkg-install with empty package fails" test_pkg_install_empty_package_fails

finish_tests
