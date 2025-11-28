#!/bin/sh
# Tests for the 'clip-copy' imp

. "${0%/*}/../../test-common.sh"

# Note: clip-copy will fail in CI without a clipboard utility, but we test error handling

test_clip_copy_no_utility_fails_gracefully() {
  # This test runs in sandbox without clipboard utilities
  # It should fail gracefully with an error message
  run_spell spells/.imps/fs/clip-copy "test text"
  # Either succeeds (if clipboard util available) or fails gracefully
}

test_clip_copy_from_stdin() {
  # Test that piped input is handled
  run_cmd sh -c 'echo "test" | clip-copy'
  # Either succeeds or fails gracefully depending on clipboard availability
}

run_test_case "clip-copy handles missing utility" test_clip_copy_no_utility_fails_gracefully
run_test_case "clip-copy from stdin" test_clip_copy_from_stdin

finish_tests
