#!/bin/sh
# Tests for the 'pkg-has' imp

. "${0%/*}/../../test-common.sh"

test_pkg_has_no_package_fails() {
  run_spell spells/.imps/pkg/pkg-has
  assert_failure
  assert_error_contains "package name required"
}

test_pkg_has_empty_package_fails() {
  run_spell spells/.imps/pkg/pkg-has ""
  assert_failure
  assert_error_contains "package name required"
}

run_test_case "pkg-has without package fails" test_pkg_has_no_package_fails
run_test_case "pkg-has with empty package fails" test_pkg_has_empty_package_fails

finish_tests
