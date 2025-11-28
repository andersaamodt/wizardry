#!/bin/sh
# Tests for the 'pkg' imp

. "${0%/*}/../test-common.sh"

test_pkg_which_returns_manager() {
  run_spell spells/.imps/pkg which
  # Should succeed and output something (whatever package manager is available)
  # On CI systems there's usually at least apt-get or similar
  assert_success
}

test_pkg_unknown_action_fails() {
  run_spell spells/.imps/pkg unknownaction
  assert_failure
  assert_error_contains "unknown action"
}

test_pkg_install_no_package_fails() {
  run_spell spells/.imps/pkg install
  assert_failure
  assert_error_contains "package name required"
}

test_pkg_remove_no_package_fails() {
  run_spell spells/.imps/pkg remove
  assert_failure
  assert_error_contains "package name required"
}

test_pkg_has_no_package_fails() {
  run_spell spells/.imps/pkg has
  assert_failure
  assert_error_contains "package name required"
}

run_test_case "pkg which returns manager" test_pkg_which_returns_manager
run_test_case "pkg unknown action fails" test_pkg_unknown_action_fails
run_test_case "pkg install without package fails" test_pkg_install_no_package_fails
run_test_case "pkg remove without package fails" test_pkg_remove_no_package_fails
run_test_case "pkg has without package fails" test_pkg_has_no_package_fails

finish_tests
