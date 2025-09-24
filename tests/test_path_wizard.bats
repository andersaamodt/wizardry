#!/usr/bin/env bats

load 'test_helper/load'

setup_home() {
  HOME="$BATS_TEST_TMPDIR/path_home"
  mkdir -p "$HOME"
  cat <<'RC' >"$HOME/.bashrc"
# test bashrc
RC
}

setup() {
  default_setup
  ORIGINAL_HOME=$HOME
  setup_home
}

teardown() {
  HOME=$ORIGINAL_HOME
  default_teardown
}

@test 'path-wizard validates arguments and manages PATH entries' {
  target_dir="$BATS_TEST_TMPDIR/target"
  mkdir -p "$target_dir"
  missing_dir="$HOME/does-not-exist"
  default_dir="$BATS_TEST_TMPDIR/default"
  mkdir -p "$default_dir"

  run_spell 'spells/path-wizard'
  assert_failure
  assert_output --partial 'requires one or two arguments'

  run_spell 'spells/path-wizard' 'list'
  assert_failure
  assert_output --partial "The first argument must be 'add' or 'remove'."

  run_spell 'spells/path-wizard' 'add' "$missing_dir"
  assert_failure
  assert_output --partial 'The directory does not exist.'

  mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
  run_spell 'spells/path-wizard' 'add' "$target_dir"
  assert_failure
  assert_output --partial "The '.bashrc' file does not exist"
  mv "$HOME/.bashrc.bak" "$HOME/.bashrc"

  run_spell 'spells/path-wizard' 'add' "$target_dir"
  assert_success
  assert_output --partial 'The directory has been added to your PATH.'
  assert_output --partial 'source ~/.bashrc'
  entry="export PATH=$target_dir:\$PATH"
  run grep -Fqx "$entry" "$HOME/.bashrc"
  assert_success

  run_spell 'spells/path-wizard' 'add' "$target_dir"
  assert_success
  assert_output --partial 'The directory is already in your PATH.'

  run_spell 'spells/path-wizard' 'remove' "$target_dir"
  assert_success
  assert_output --partial 'The directory has been removed from your PATH.'
  assert_output --partial 'open a new terminal'
  run grep -Fqx "$entry" "$HOME/.bashrc"
  assert_failure

  run_spell 'spells/path-wizard' 'remove' "$target_dir"
  assert_failure
  assert_output --partial 'The directory is not in your PATH.'

  old_pwd=$(pwd)
  cd "$default_dir"
  run_spell 'spells/path-wizard' 'add'
  cd "$old_pwd"
  assert_success
  default_entry="export PATH=$default_dir:\$PATH"
  run grep -Fqx "$default_entry" "$HOME/.bashrc"
  assert_success

  run_spell 'spells/path-wizard' 'remove' "$default_dir"
  assert_success

  magic_dir="$HOME/magic"
  mkdir -p "$magic_dir"
  run_spell 'spells/path-wizard' 'add' '~/magic'
  assert_success
  tilde_entry="export PATH=$magic_dir:\$PATH"
  run grep -Fqx "$tilde_entry" "$HOME/.bashrc"
  assert_success
  run_spell 'spells/path-wizard' 'remove' "$magic_dir"
  assert_success

  dot_dir="$BATS_TEST_TMPDIR/dot"
  mkdir -p "$dot_dir"
  old_pwd=$(pwd)
  cd "$dot_dir"
  run_spell 'spells/path-wizard' 'add' '.'
  cd "$old_pwd"
  assert_success
  dot_entry="export PATH=$dot_dir:\$PATH"
  run grep -Fqx "$dot_entry" "$HOME/.bashrc"
  assert_success
  run_spell 'spells/path-wizard' 'remove' "$dot_dir"
  assert_success

  relative_dir="$HOME/relative"
  mkdir -p "$relative_dir"
  old_pwd=$(pwd)
  cd "$HOME"
  run_spell 'spells/path-wizard' 'add' 'relative'
  cd "$old_pwd"
  assert_success
  relative_entry="export PATH=$relative_dir:\$PATH"
  run grep -Fqx "$relative_entry" "$HOME/.bashrc"
  assert_success
  run_spell 'spells/path-wizard' 'remove' "$relative_dir"
  assert_success
}

