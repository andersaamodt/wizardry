#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_HOME=$HOME
  HOME="$BATS_TEST_TMPDIR/spell_home"
  export HOME
  mkdir -p "$HOME"
}

teardown() {
  HOME=$ORIGINAL_HOME
  export HOME
  default_teardown
}

spellbook_file() {
  printf '%s\n' "$HOME/.tower/spellbook"
}

@test 'spellbook-store records and removes entries' {
  run_spell 'spells/cantrips/spellbook-store' add jump 'jump-to-marker'
  assert_success

  run cat "$(spellbook_file)"
  assert_success
  assert_output $'jump\tjump-to-marker'

  run_spell 'spells/cantrips/spellbook-store' remove jump
  assert_success

  if [ -f "$(spellbook_file)" ]; then
    run cat "$(spellbook_file)"
    assert_success
    [ -z "$output" ]
  fi
}

@test 'memorize alias updates spellbook' {
  run_spell 'spells/memorize' alias portal "echo portal"
  assert_success

  run cat "$(spellbook_file)"
  assert_success
  assert_output --partial $'portal\techo portal'
}

@test 'spellbook --forget removes entries' {
  run_spell 'spells/cantrips/spellbook-store' add starlight 'printf starlight'
  assert_success

  run_spell 'spells/menu/spellbook' --forget starlight
  assert_success
  assert_output --partial "Forgot 'starlight'"

  if [ -f "$(spellbook_file)" ]; then
    run cat "$(spellbook_file)"
    assert_success
    [ -z "$output" ]
  fi
}

@test 'spellbook and spell-menu list the same spells' {
  run_spell 'spells/cantrips/spellbook-store' add jump 'jump-to-marker'
  assert_success
  run_spell 'spells/cantrips/spellbook-store' add mark 'mark-location'
  assert_success

  run_spell 'spells/menu/spellbook' --list
  assert_success
  spellbook_list="$output"

  run_spell 'spells/menu/spell-menu' --list
  assert_success
  assert_equal "$spellbook_list" "$output"
}
