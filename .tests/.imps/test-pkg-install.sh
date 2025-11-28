#!/bin/sh
# Tests for the 'pkg-install' imp

. "${0%/*}/../test-common.sh"

test_pkg_install_no_package_fails() {
  run_spell spells/.imps/pkg-install
  assert_failure
  assert_error_contains "package name required"
}

test_pkg_install_empty_package_fails() {
  run_spell spells/.imps/pkg-install ""
  assert_failure
  assert_error_contains "package name required"
}

run_test_case "pkg-install without package fails" test_pkg_install_no_package_fails
run_test_case "pkg-install with empty package fails" test_pkg_install_empty_package_fails

finish_tests
