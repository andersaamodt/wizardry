#!/bin/sh
# Integration test for MUD multiplayer proof-of-concept
# Tests: portal, look, say, magic-missile in a shared environment

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_multiplayer_workflow() {
  # Create a shared "dungeon" directory
  shared_dungeon=$(make_tempdir)/dungeon
  mkdir -p "$shared_dungeon"
  
  # Set up room with title and description
  if command -v enchant >/dev/null 2>&1 && command -v read-magic >/dev/null 2>&1; then
    enchant "$shared_dungeon" "title=The Grand Hall" >/dev/null 2>&1 || true
    enchant "$shared_dungeon" "description=A vast chamber with soaring ceilings and magical torches." >/dev/null 2>&1 || true
  fi
  
  # Player 1: Look around (should see room)
  cd "$shared_dungeon" || return 1
  MUD_PLAYER="Player1" run_spell "spells/mud/look"
  assert_success || return 1
  
  # Player 1: Say something
  MUD_PLAYER="Player1" run_spell "spells/mud/say" "Hello, is anyone here?"
  assert_success || return 1
  assert_output_contains "Player1 says: Hello, is anyone here?" || return 1
  
  # Check room log was created
  [ -f "$shared_dungeon/.room.log" ] || return 1
  
  # Player 2: Look around (should see Player 1's message in recent activity)
  MUD_PLAYER="Player2" run_spell "spells/mud/look"
  assert_success || return 1
  assert_output_contains "Recent Activity" || return 1
  assert_output_contains "Player1 says" || return 1
  
  # Player 2: Say something back
  MUD_PLAYER="Player2" run_spell "spells/mud/say" "Hi Player1! I'm here now."
  assert_success || return 1
  
  # Create a target for magic missile
  target_file="$shared_dungeon/treasure-chest"
  printf 'A wooden chest\n' > "$target_file"
  
  # Give it some starting health if enchant is available
  if command -v enchant >/dev/null 2>&1; then
    enchant "$target_file" "life=100" >/dev/null 2>&1 || true
  fi
  
  # Player 1: Cast magic missile
  MUD_PLAYER="Player1" run_spell "spells/mud/magic-missile" "$target_file"
  # Note: This might fail if mana system is enforced, but spell should still try
  
  # Check that combat was logged
  grep -q "magic missile" "$shared_dungeon/.room.log" || return 1
  
  # Player 2: Look again (should see the combat in recent activity)
  MUD_PLAYER="Player2" run_spell "spells/mud/look"
  assert_success || return 1
  assert_output_contains "magic missile" || return 1
  
  # Verify room log has all events
  log_count=$(wc -l < "$shared_dungeon/.room.log")
  [ "$log_count" -ge 3 ] || return 1  # At least 2 says + 1 combat
}

test_say_and_look_integration() {
  # Test that say creates log and look shows it
  room=$(make_tempdir)
  cd "$room" || return 1
  
  # Say something
  MUD_PLAYER="Alice" run_spell "spells/mud/say" "Testing"
  assert_success || return 1
  
  # Look should show recent activity
  MUD_PLAYER="Bob" run_spell "spells/mud/look"
  assert_success || return 1
  assert_output_contains "Recent Activity" || return 1
  assert_output_contains "Alice says: Testing" || return 1
}

run_test_case "multiplayer workflow (look, say, magic-missile)" test_multiplayer_workflow
run_test_case "say and look integration" test_say_and_look_integration

finish_tests
