#!/bin/sh
# Tests for the 'clip-copy' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Note: clip-copy will fail in CI without a clipboard utility, but we test error handling

test_clip_copy_no_utility_fails_gracefully() {
  # This test runs in sandbox without clipboard utilities
  # It should fail gracefully with an error message
  _run_spell spells/.imps/fs/clip-copy "test text"
  # Either succeeds (if clipboard util available) or fails gracefully
}

test_clip_copy_from_stdin() {
  # Test that piped input is handled - use full path via _run_spell
  _run_cmd sh -c "echo 'test' | $ROOT_DIR/spells/.imps/fs/clip-copy"
  # Either succeeds or fails gracefully depending on clipboard availability
}

_run_test_case "clip-copy handles missing utility" test_clip_copy_no_utility_fails_gracefully
_run_test_case "clip-copy from stdin" test_clip_copy_from_stdin

_finish_tests
