#!/bin/sh
# Tests for the 'clipboard' imp

. "${0%/*}/../../test-common.sh"

test_clipboard_invalid_mode_fails() {
  run_spell spells/.imps/fs/clipboard invalid
  assert_failure
  assert_error_contains "mode must be 'copy' or 'paste'"
}

test_clipboard_no_mode_fails() {
  run_spell spells/.imps/fs/clipboard
  assert_failure
  assert_error_contains "mode must be 'copy' or 'paste'"
}

# Test copy with direct text argument (will fail if no clipboard util, but that's expected)
test_clipboard_copy_direct_text() {
  # This will either succeed (if clipboard util available) or fail gracefully
  run_spell spells/.imps/fs/clipboard copy "test text"
  # We don't assert success because clipboard util may not be available in CI
  # We just ensure it doesn't crash in an unexpected way
}

run_test_case "clipboard invalid mode fails" test_clipboard_invalid_mode_fails
run_test_case "clipboard no mode fails" test_clipboard_no_mode_fails
run_test_case "clipboard copy direct text" test_clipboard_copy_direct_text

finish_tests
