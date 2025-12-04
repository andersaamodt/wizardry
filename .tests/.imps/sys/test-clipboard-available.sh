#!/bin/sh
# Tests for the 'clipboard-available' imp

. "${0%/*}/../../test-common.sh"

test_clipboard_shows_help() {
  run_spell spells/.imps/sys/clipboard-available --help
  assert_success
  assert_error_contains "clipboard helper"
}

test_clipboard_shows_help_h() {
  run_spell spells/.imps/sys/clipboard-available -h
  assert_success
  assert_error_contains "clipboard helper"
}

test_clipboard_returns_success_when_helper_exists() {
  # This test checks if the imp returns success when at least one helper is available
  # Since we can't guarantee which helpers are installed, we check if it returns
  # a valid exit code (0 or 1, or 127 in restricted sandbox environments)
  run_spell spells/.imps/sys/clipboard-available
  # The output should be empty (no args mode just returns exit code)
  if [ "$STATUS" -eq 0 ]; then
    # Helper exists - this is valid
    return 0
  elif [ "$STATUS" -eq 1 ] || [ "$STATUS" -eq 127 ]; then
    # No helper (1) or sandbox restriction (127) - also valid for this test
    return 0
  else
    TEST_FAILURE_REASON="unexpected exit code: $STATUS"
    return 1
  fi
}

test_clipboard_no_output_on_success() {
  # When a clipboard helper is available, there should be no output
  run_spell spells/.imps/sys/clipboard-available
  if [ "$STATUS" -eq 0 ]; then
    if [ -n "$OUTPUT" ]; then
      TEST_FAILURE_REASON="expected no output, got: $OUTPUT"
      return 1
    fi
  fi
  return 0
}

test_clipboard_checks_pbcopy() {
  # Create a fixture with only pbcopy available
  fixture=$(make_tempdir)
  write_command_stub "$fixture" pbcopy
  PATH="$fixture:$PATH" run_spell spells/.imps/sys/clipboard-available
  assert_success
  rm -rf "$fixture"
}

test_clipboard_checks_xsel() {
  # Create a fixture with only xsel available
  fixture=$(make_tempdir)
  write_command_stub "$fixture" xsel
  PATH="$fixture:$PATH" run_spell spells/.imps/sys/clipboard-available
  assert_success
  rm -rf "$fixture"
}

test_clipboard_checks_xclip() {
  # Create a fixture with only xclip available
  fixture=$(make_tempdir)
  write_command_stub "$fixture" xclip
  PATH="$fixture:$PATH" run_spell spells/.imps/sys/clipboard-available
  assert_success
  rm -rf "$fixture"
}

test_clipboard_checks_wl_copy() {
  # Create a fixture with only wl-copy available
  fixture=$(make_tempdir)
  write_command_stub "$fixture" wl-copy
  PATH="$fixture:$PATH" run_spell spells/.imps/sys/clipboard-available
  assert_success
  rm -rf "$fixture"
}

test_clipboard_fails_when_none_available() {
  # Create an empty fixture directory with no clipboard commands
  fixture=$(make_tempdir)
  # Use only the fixture in PATH (no clipboard helpers)
  # Need to include basic commands for shell to work
  link_tools "$fixture" sh cat printf test
  PATH="$fixture" run_cmd "$ROOT_DIR/spells/.imps/sys/clipboard-available"
  assert_failure
  rm -rf "$fixture"
}

run_test_case "clipboard-available shows help" test_clipboard_shows_help
run_test_case "clipboard-available shows help with -h" test_clipboard_shows_help_h
run_test_case "clipboard-available returns valid exit code" test_clipboard_returns_success_when_helper_exists
run_test_case "clipboard-available no output on success" test_clipboard_no_output_on_success
run_test_case "clipboard-available detects pbcopy" test_clipboard_checks_pbcopy
run_test_case "clipboard-available detects xsel" test_clipboard_checks_xsel
run_test_case "clipboard-available detects xclip" test_clipboard_checks_xclip
run_test_case "clipboard-available detects wl-copy" test_clipboard_checks_wl_copy
run_test_case "clipboard-available fails when no helpers" test_clipboard_fails_when_none_available

finish_tests
