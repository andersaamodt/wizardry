#!/bin/sh
# Tests for the 'ensure-dir' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_ensure_dir_creates_directory() {
  tmpdir="$WIZARDRY_TMPDIR/ensure_dir_test_$$"
  "$ROOT_DIR/spells/.imps/paths/ensure-dir" "$tmpdir"
  if [ -d "$tmpdir" ]; then
    rm -rf "$tmpdir"
    return 0
  fi
  TEST_FAILURE_REASON="ensure-dir should create directory"
  return 1
}

test_ensure_dir_handles_existing() {
  tmpdir="$WIZARDRY_TMPDIR/ensure_dir_existing_$$"
  mkdir -p "$tmpdir"
  "$ROOT_DIR/spells/.imps/paths/ensure-dir" "$tmpdir"
  if [ -d "$tmpdir" ]; then
    rm -rf "$tmpdir"
    return 0
  fi
  TEST_FAILURE_REASON="ensure-dir should handle existing directory"
  return 1
}

run_test_case "ensure-dir creates directory" test_ensure_dir_creates_directory
run_test_case "ensure-dir handles existing directory" test_ensure_dir_handles_existing

finish_tests
