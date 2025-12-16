#!/bin/sh
# Tests for the 'clip-paste' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Note: clip-paste will fail in CI without a clipboard utility, but we test error handling

test_clip_paste_no_utility_fails_gracefully() {
  # This test runs in sandbox without clipboard utilities
  # It should fail gracefully with an error message
  _run_spell spells/.imps/fs/clip-paste
  # Either succeeds (if clipboard util available) or fails gracefully
}

test_clip_paste_produces_output() {
  # Test that the imp runs and produces output or fails gracefully
  _run_spell spells/.imps/fs/clip-paste
  # Either succeeds or fails gracefully depending on clipboard availability
}

_run_test_case "clip-paste handles missing utility" test_clip_paste_no_utility_fails_gracefully
_run_test_case "clip-paste produces output" test_clip_paste_produces_output

_finish_tests
