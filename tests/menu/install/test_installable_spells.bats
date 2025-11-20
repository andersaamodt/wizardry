#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_HOME=$HOME
  HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  touch "$HOME/.bashrc"
}

teardown() {
  HOME=$ORIGINAL_HOME
  default_teardown
}

@test 'cd cantrip prompts to install itself when invoked directly' {
  input_yes="$BATS_TEST_TMPDIR/cd_yes"
  printf 'y\n' >"$input_yes"

  ASK_CANTRIP_INPUT=stdin run_spell 'spells/cantrips/cd' <"$input_yes"
  assert_success
  assert_error --partial "Memorize the cd cantrip in .bashrc"
  assert_output --partial "The hook is etched into .bashrc"

  run grep -F "# >>> wizardry cd cantrip >>>" "$HOME/.bashrc"
  assert_success
}
