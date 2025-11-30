#!/bin/sh
# Tests for the 'pkg-remove' imp

. "${0%/*}/../../test-common.sh"

test_pkg_remove_no_package_fails() {
  run_spell spells/.imps/pkg/pkg-remove
  assert_failure
  assert_error_contains "package name required"
}

test_pkg_remove_empty_package_fails() {
  run_spell spells/.imps/pkg/pkg-remove ""
  assert_failure
  assert_error_contains "package name required"
}

run_test_case "pkg-remove without package fails" test_pkg_remove_no_package_fails
run_test_case "pkg-remove with empty package fails" test_pkg_remove_empty_package_fails

finish_tests
