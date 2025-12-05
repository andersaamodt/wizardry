#!/bin/sh
# Tests for the 'pkg-manager' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

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
