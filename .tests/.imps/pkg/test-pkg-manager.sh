#!/bin/sh
# Tests for the 'pkg-manager' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
