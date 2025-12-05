#!/bin/sh
# Tests for the 'pkg-remove' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
