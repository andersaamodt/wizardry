#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_HOME=$HOME
  ORIGINAL_PATH=$PATH
  HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  touch "$HOME/.bashrc"

  stub_dir="$BATS_TEST_TMPDIR/look_stub"
  mkdir -p "$stub_dir/bin"
  cat <<'LOOK' >"$stub_dir/bin/look"
#!/usr/bin/env bash
echo "Peering into $(pwd)"
LOOK
  chmod +x "$stub_dir/bin/look"
}

teardown() {
  HOME=$ORIGINAL_HOME
  PATH=$ORIGINAL_PATH
  default_teardown
}

with_stub_path() {
  PATH="$stub_dir/bin:$ORIGINAL_PATH" "$@"
}

memorize_jump() {
  printf 'source %s/jump-to-marker\n' "$ROOT_DIR/spells" >>"$HOME/.bashrc"
}

@test 'jump-to-marker memorizes spell and warns when no marker exists' {
  input="$BATS_TEST_TMPDIR/input_yes"
  printf 'y\n' >"$input"
  ASK_CANTRIP_INPUT=stdin with_stub_path run_spell 'spells/jump-to-marker' <"$input"
  assert_success
  assert_output --partial "Memorize the 'jump' spell now?"
  assert_output --partial "The 'jump' spell has been memorized"
  assert_output --partial "Spellbook updated: 'jump' now casts 'jump-to-marker'."
  assert_output --partial 'No location has been marked'
  assert_output --partial 'Peering'

  run cat "$HOME/.tower/spellbook"
  assert_success
  assert_output --partial $'jump\tjump-to-marker'

  run cat "$HOME/.bashrc"
  assert_success
  assert_output --partial 'source'
}

@test 'mark-location records current directory and explicit paths' {
  destination="$BATS_TEST_TMPDIR/destination"
  mkdir -p "$destination"
  pushd "$destination" >/dev/null
  with_stub_path run_spell 'spells/mark-location'
  popd >/dev/null
  assert_success

  marker_file="$HOME/.mud/portal_marker"
  run cat "$marker_file"
  assert_success
  assert_output "$destination"

  other_target="$BATS_TEST_TMPDIR/other"
  mkdir -p "$other_target"
  with_stub_path run_spell 'spells/mark-location' "$other_target"
  assert_success
  run cat "$marker_file"
  assert_success
  assert_output "$other_target"
}

@test 'jump-to-marker travels to marked location when memorized' {
  other_target="$BATS_TEST_TMPDIR/marked"
  mkdir -p "$other_target"
  with_stub_path run_spell 'spells/mark-location' "$other_target"
  assert_success

  traveller="$BATS_TEST_TMPDIR/traveller"
  mkdir -p "$traveller"
  pushd "$traveller" >/dev/null
  memorize_jump
  RANDOM=0 with_stub_path run_spell 'spells/jump-to-marker'
  popd >/dev/null
  assert_success
  assert_output --partial "Peering into $other_target"
  [[ "$output" != *Memorize* ]]
}

@test 'jump-to-marker warns when marker missing' {
  marker_file="$HOME/.mud/portal_marker"
  rm -f "$marker_file"
  memorize_jump
  with_stub_path run_spell 'spells/jump-to-marker'
  assert_success
  assert_output --partial 'No location has been marked'
}

