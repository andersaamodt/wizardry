#!/bin/sh
# Test coverage for say spell:
# - Shows usage with --help
# - Requires a message argument
# - Appends message to the operator-local room activity log
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
  room_log=$(HOME="$tmpdir" sh "$test_root/spells/.imps/mud/log-path" "$tmpdir")
  
  # Say something (should be silent)
  OUTPUT=$(HOME="$tmpdir" MUD_PLAYER="TestPlayer" sh "$test_root/spells/mud/say" "Hello world" 2>"$tmpdir/error")
  status=$?
  [ "$status" -eq 0 ] || return 1
  [ ! -s "$tmpdir/error" ] || return 1
  
  # Should not output anything by default
  [ -z "$OUTPUT" ] || return 1
  
  # Check room activity log was created outside the repo/workspace root
  [ -f "$room_log" ] || return 1
  
  # Check log contains the message
  grep -q "TestPlayer: Hello world" "$room_log" || return 1
}

test_verbose_flag() {
  tmpdir=$(make_tempdir)
  cd "$tmpdir" || return 1
  room_log=$(HOME="$tmpdir" sh "$test_root/spells/.imps/mud/log-path" "$tmpdir")
  
  # Say something with -v flag
  OUTPUT=$(HOME="$tmpdir" MUD_PLAYER="TestPlayer" sh "$test_root/spells/mud/say" -v "Hello world" 2>"$tmpdir/error")
  status=$?
  [ "$status" -eq 0 ] || return 1
  [ ! -s "$tmpdir/error" ] || return 1
  
  # Should output with -v
  printf '%s' "$OUTPUT" | grep -q "TestPlayer: Hello world" || return 1
  
  # Check room activity log was created
  [ -f "$room_log" ] || return 1
  grep -q "TestPlayer: Hello world" "$room_log" || return 1
}

test_multiple_messages() {
  tmpdir=$(make_tempdir)
  cd "$tmpdir" || return 1
  room_log=$(HOME="$tmpdir" sh "$test_root/spells/.imps/mud/log-path" "$tmpdir")
  
  # Say multiple things (silent)
  HOME="$tmpdir" MUD_PLAYER="Player1" sh "$test_root/spells/mud/say" "First message" >/dev/null 2>"$tmpdir/error1" || return 1
  [ ! -s "$tmpdir/error1" ] || return 1
  
  HOME="$tmpdir" MUD_PLAYER="Player2" sh "$test_root/spells/mud/say" "Second message" >/dev/null 2>"$tmpdir/error2" || return 1
  [ ! -s "$tmpdir/error2" ] || return 1
  
  # Check both are in log
  grep -q "Player1: First message" "$room_log" || return 1
  grep -q "Player2: Second message" "$room_log" || return 1
  
  # Check we have 2 lines
  line_count=$(wc -l < "$room_log")
  [ "$line_count" -eq 2 ] || return 1
}

run_test_case "say shows usage text" test_help
run_test_case "say requires message" test_requires_message
run_test_case "say is silent by default" test_appends_to_log_silent
run_test_case "say outputs with -v flag" test_verbose_flag
run_test_case "say handles multiple messages" test_multiple_messages

finish_tests
