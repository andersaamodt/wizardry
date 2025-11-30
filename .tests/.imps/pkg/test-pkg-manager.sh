#!/bin/sh
# Tests for the 'pkg-manager' imp

. "${0%/*}/../../test-common.sh"

test_pkg_manager_returns_name() {
  run_spell spells/.imps/pkg/pkg-manager
  # Should succeed and output a package manager name (apt, dnf, etc.)
  assert_success
}

test_pkg_manager_output_is_valid() {
  run_spell spells/.imps/pkg/pkg-manager
  assert_success
  case "$OUTPUT" in
    apt|dnf|pacman|brew|nix|pkgin|apk) : ;;
    *) TEST_FAILURE_REASON="unexpected output: $OUTPUT"; return 1 ;;
  esac
}

run_test_case "pkg-manager returns name" test_pkg_manager_returns_name
run_test_case "pkg-manager output is valid" test_pkg_manager_output_is_valid

finish_tests
