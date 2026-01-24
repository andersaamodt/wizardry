#!/bin/sh
# Test coverage for think spell:
# - Shows usage with --help
# - Requires a thought argument  
# - Appends thought to avatar's .log with quotes format
# - Includes timestamp and player name
# - Fails if no avatar exists

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

test_appends_to_avatar_log() {
  tmpdir=$(make_tempdir)
  cd "$tmpdir" || return 1
  
  # Create avatar folder
  mkdir -p ".testplayer"
  
  # Set up config to point to this avatar
  config_home=$(make_tempdir)
  mkdir -p "$config_home/.spellbook"
  config_file="$config_home/.spellbook/.mud"
  printf 'avatar-path=%s/.testplayer\n' "$tmpdir" > "$config_file"
  
  # Think something
  SPELLBOOK_DIR="$config_home/.spellbook" MUD_PLAYER="testplayer" run_spell "spells/mud/think" "I wonder what's next"
  assert_success || return 1
  
  # Check avatar log file was created (not room log)
  [ -f ".testplayer/.log" ] || return 1
  [ ! -f ".log" ] || return 1
  
  # Check log contains the thought with correct format (name thinks, "thought")
  grep -q 'testplayer thinks, "I wonder what'"'"'s next"' .testplayer/.log || return 1
}

test_fails_without_avatar() {
  tmpdir=$(make_tempdir)
  cd "$tmpdir" || return 1
  
  # Set up empty config
  config_home=$(make_tempdir)
  mkdir -p "$config_home/.spellbook"
  
  # Try to think without avatar
  SPELLBOOK_DIR="$config_home/.spellbook" MUD_PLAYER="testplayer" run_spell "spells/mud/think" "test thought"
  assert_failure || return 1
  assert_error_contains "no avatar found" || return 1
}

run_test_case "think shows usage text" test_help
run_test_case "think requires thought" test_requires_thought
run_test_case "think appends to avatar log" test_appends_to_avatar_log
run_test_case "think fails without avatar" test_fails_without_avatar

finish_tests
