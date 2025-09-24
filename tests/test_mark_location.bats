#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_HOME=$HOME
  HOME="$BATS_TEST_TMPDIR/mark_home"
  mkdir -p "$HOME"
}

teardown() {
  HOME=$ORIGINAL_HOME
  default_teardown
}

marker_file() {
  printf '%s/.mud/portal_marker\n' "$HOME"
}

read_marker() {
  cat "$(marker_file)"
}

@test 'mark-location records current directory when no arguments given' {
  destination="$BATS_TEST_TMPDIR/destination"
  mkdir -p "$destination"
  pushd "$destination" >/dev/null
  run_spell 'spells/mark-location'
  popd >/dev/null

  assert_success
  assert_output --partial 'Location marked at'
  run read_marker
  assert_success
  assert_output "$destination"
}

@test 'mark-location resolves relative paths to absolute locations' {
  mkdir -p "$HOME/vault/treasure"
  pushd "$HOME" >/dev/null
  run_spell 'spells/mark-location' 'vault/treasure'
  popd >/dev/null

  assert_success
  run read_marker
  assert_success
  assert_output "$HOME/vault/treasure"
}

@test 'mark-location writes provided paths without validation' {
  run_spell 'spells/mark-location' "$HOME/nonexistent/place"
  assert_failure
  [[ "$stderr" == *'does not exist'* ]]

  run_spell 'spells/mark-location' "$HOME/one" "$HOME/two"
  assert_failure
  [[ "$stderr" == *'Usage'* ]]
}

