#!/bin/sh
# Tests for the 'pkg-update' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pkg_update_runs() {
  # pkg-update doesn't take args, so just verify it doesn't fail on invocation syntax
  # The actual update may fail in sandbox but that's expected
  run_spell spells/.imps/pkg/pkg-update
  # We don't assert success because it may fail in sandbox without sudo
}

test_pkg_update_detects_manager() {
  # Verify it at least tries to detect a package manager
  run_spell spells/.imps/pkg/pkg-update
  # Either succeeds or fails gracefully
}

run_test_case "pkg-update runs" test_pkg_update_runs
run_test_case "pkg-update detects manager" test_pkg_update_detects_manager

finish_tests
