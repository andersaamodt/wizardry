#!/bin/sh
# Test coverage for think spell:
# - Shows usage with --help
# - Requires a thought argument  
# - Appends thought to .room.log with parentheses format
# - Includes timestamp and player name

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/mud/think" --help
  assert_success || return 1
  assert_output_contains "Usage: think" || return 1
}

test_requires_thought() {
  run_spell "spells/mud/think"
  assert_failure || return 1
  assert_error_contains "requires a thought" || return 1
}

test_appends_to_log() {
  tmpdir=$(make_tempdir)
  cd "$tmpdir" || return 1
  
  # Think something
  MUD_PLAYER="TestPlayer" run_spell "spells/mud/think" "I wonder what's next"
  assert_success || return 1
  
  # Check log file was created
  [ -f ".room.log" ] || return 1
  
  # Check log contains the thought with correct format
  grep -q "TestPlayer thinks: I wonder what's next" .room.log || return 1
  grep -q "(TestPlayer thinks:" .room.log || return 1
}

test_multiple_thoughts() {
  tmpdir=$(make_tempdir)
  cd "$tmpdir" || return 1
  
  # Think multiple things
  MUD_PLAYER="Player1" run_spell "spells/mud/think" "Where is everyone?"
  assert_success || return 1
  
  MUD_PLAYER="Player2" run_spell "spells/mud/think" "This is strange"
  assert_success || return 1
  
  # Check both are in log
  grep -q "Player1 thinks: Where is everyone?" .room.log || return 1
  grep -q "Player2 thinks: This is strange" .room.log || return 1
  
  # Check we have 2 lines
  line_count=$(wc -l < .room.log)
  [ "$line_count" -eq 2 ] || return 1
}

run_test_case "think shows usage text" test_help
run_test_case "think requires thought" test_requires_thought
run_test_case "think appends to room log" test_appends_to_log
run_test_case "think handles multiple thoughts" test_multiple_thoughts

finish_tests
