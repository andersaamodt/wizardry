#!/bin/sh
# Test coverage for say spell:
# - Shows usage with --help
# - Requires a message argument
# - Appends message to .log
# - Includes timestamp and player name
# - Silent by default, verbose with -v

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/mud/say" --help
  assert_success || return 1
  assert_output_contains "Usage: say" || return 1
}

test_requires_message() {
  run_spell "spells/mud/say"
  assert_failure || return 1
  assert_error_contains "requires a message" || return 1
}

test_appends_to_log_silent() {
  tmpdir=$(make_tempdir)
  cd "$tmpdir" || return 1
  
  # Say something (should be silent)
  MUD_PLAYER="TestPlayer" run_spell "spells/mud/say" "Hello world"
  assert_success || return 1
  
  # Should not output anything by default
  [ -z "$OUTPUT" ] || return 1
  
  # Check log file was created
  [ -f ".log" ] || return 1
  
  # Check log contains the message
  grep -q "TestPlayer: Hello world" .log || return 1
}

test_verbose_flag() {
  tmpdir=$(make_tempdir)
  cd "$tmpdir" || return 1
  
  # Say something with -v flag
  MUD_PLAYER="TestPlayer" run_spell "spells/mud/say" -v "Hello world"
  assert_success || return 1
  
  # Should output with -v
  assert_output_contains "TestPlayer: Hello world" || return 1
  
  # Check log file was created
  [ -f ".log" ] || return 1
  grep -q "TestPlayer: Hello world" .log || return 1
}

test_multiple_messages() {
  tmpdir=$(make_tempdir)
  cd "$tmpdir" || return 1
  
  # Say multiple things (silent)
  MUD_PLAYER="Player1" run_spell "spells/mud/say" "First message"
  assert_success || return 1
  
  MUD_PLAYER="Player2" run_spell "spells/mud/say" "Second message"
  assert_success || return 1
  
  # Check both are in log
  grep -q "Player1: First message" .log || return 1
  grep -q "Player2: Second message" .log || return 1
  
  # Check we have 2 lines
  line_count=$(wc -l < .log)
  [ "$line_count" -eq 2 ] || return 1
}

run_test_case "say shows usage text" test_help
run_test_case "say requires message" test_requires_message
run_test_case "say is silent by default" test_appends_to_log_silent
run_test_case "say outputs with -v flag" test_verbose_flag
run_test_case "say handles multiple messages" test_multiple_messages

finish_tests
