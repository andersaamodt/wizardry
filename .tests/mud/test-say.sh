#!/bin/sh
# Test coverage for say spell:
# - Shows usage with --help
# - Requires a message argument
# - Appends message to .room.log
# - Includes timestamp and player name

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

test_appends_to_log() {
  tmpdir=$(make_tempdir)
  cd "$tmpdir" || return 1
  
  # Say something
  MUD_PLAYER="TestPlayer" run_spell "spells/mud/say" "Hello world"
  assert_success || return 1
  
  # Check log file was created
  [ -f ".room.log" ] || return 1
  
  # Check log contains the message
  grep -q "TestPlayer says: Hello world" .room.log || return 1
  grep -q "Hello world" .room.log || return 1
}

test_multiple_messages() {
  tmpdir=$(make_tempdir)
  cd "$tmpdir" || return 1
  
  # Say multiple things
  MUD_PLAYER="Player1" run_spell "spells/mud/say" "First message"
  assert_success || return 1
  
  MUD_PLAYER="Player2" run_spell "spells/mud/say" "Second message"
  assert_success || return 1
  
  # Check both are in log
  grep -q "Player1 says: First message" .room.log || return 1
  grep -q "Player2 says: Second message" .room.log || return 1
  
  # Check we have 2 lines
  line_count=$(wc -l < .room.log)
  [ "$line_count" -eq 2 ] || return 1
}

run_test_case "say shows usage text" test_help
run_test_case "say requires message" test_requires_message
run_test_case "say appends to room log" test_appends_to_log
run_test_case "say handles multiple messages" test_multiple_messages

finish_tests
