#!/usr/bin/env bats

load 'test_helper/load'

setup_home() {
  HOME="$BATS_TEST_TMPDIR/path_home"
  export HOME
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
  export HOME
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
  assert_error --partial 'Usage: path-wizard'

  run_spell 'spells/path-wizard' 'list'
  assert_failure
  assert_error --partial "The first argument must be 'add', 'remove', or 'status'."

  run_spell 'spells/path-wizard' 'add' "$missing_dir"
  assert_failure
  assert_error --partial 'The directory does not exist.'

  mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
  run_spell 'spells/path-wizard' 'add' "$target_dir"
  assert_success
  assert_output --partial "Added '$target_dir' to PATH via '$HOME/.bashrc'"
  assert_output --partial 'Open a new shell'
  mv "$HOME/.bashrc.bak" "$HOME/.bashrc"

  run_spell 'spells/path-wizard' 'add' "$target_dir"
  assert_success
  assert_output --partial "Added '$target_dir' to PATH via '$HOME/.bashrc'"
  assert_output --partial 'Open a new shell'
  entry=$(printf 'export PATH="%s:$PATH"' "$target_dir")
  run grep -Fq "$entry" "$HOME/.bashrc"
  assert_success

  run_spell 'spells/path-wizard' 'status' "$target_dir"
  assert_success

  run_spell 'spells/path-wizard' 'add' "$target_dir"
  assert_success
  assert_output --partial "'$target_dir' is already exported in '$HOME/.bashrc'"

  run_spell 'spells/path-wizard' 'remove' "$target_dir"
  assert_success
  assert_output --partial "Removed '$target_dir' from PATH entries recorded in '$HOME/.bashrc'"
  assert_output --partial 'Open a new shell'
  run grep -Fq "$entry" "$HOME/.bashrc"
  assert_failure

  run_spell 'spells/path-wizard' 'status' "$target_dir"
  assert_failure

  run_spell 'spells/path-wizard' 'remove' "$target_dir"
  assert_failure
  assert_error --partial 'The directory is not in your PATH.'

  old_pwd=$(pwd)
  cd "$default_dir"
  run_spell 'spells/path-wizard' 'add'
  cd "$old_pwd"
  assert_success
  default_entry=$(printf 'export PATH="%s:$PATH"' "$default_dir")
  run grep -Fq "$default_entry" "$HOME/.bashrc"
  assert_success

  run_spell 'spells/path-wizard' 'remove' "$default_dir"
  assert_success

  magic_dir="$HOME/magic"
  mkdir -p "$magic_dir"
  run_spell 'spells/path-wizard' 'add' '~/magic'
  assert_success
  tilde_entry=$(printf 'export PATH="%s:$PATH"' "$magic_dir")
  run grep -Fq "$tilde_entry" "$HOME/.bashrc"
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
  dot_entry=$(printf 'export PATH="%s:$PATH"' "$dot_dir")
  run grep -Fq "$dot_entry" "$HOME/.bashrc"
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
  relative_entry=$(printf 'export PATH="%s:$PATH"' "$relative_dir")
  run grep -Fq "$relative_entry" "$HOME/.bashrc"
  assert_success
  run_spell 'spells/path-wizard' 'remove' "$relative_dir"
  assert_success
}


@test 'path-wizard refreshes legacy escaped PATH entries' {
  target_dir="$BATS_TEST_TMPDIR/legacy"
  mkdir -p "$target_dir"

  legacy_entry=$(printf 'export PATH=%s:\\$PATH' "$target_dir")
  printf '%s\n' "$legacy_entry" >>"$HOME/.bashrc"

  run_spell 'spells/path-wizard' 'add' "$target_dir"
  assert_success
  assert_output --partial 'Refreshed the existing wizardry PATH entry'

  fixed_entry=$(printf 'export PATH="%s:$PATH"' "$target_dir")
  run grep -Fq "$fixed_entry" "$HOME/.bashrc"
  assert_success

  run grep -Fq "$legacy_entry" "$HOME/.bashrc"
  assert_failure

  run_spell 'spells/path-wizard' 'remove' "$target_dir"
  assert_success
}


@test 'path-wizard recursively manages nested directories' {
  base_dir="$BATS_TEST_TMPDIR/recursive"
  mkdir -p "$base_dir/level1/level2"

  run_spell 'spells/path-wizard' '-r' 'status' "$base_dir"
  assert_failure

  run_spell 'spells/path-wizard' '-r' 'add' "$base_dir"
  assert_success

  base_entry=$(printf 'export PATH="%s:$PATH"' "$base_dir")
  level1_entry=$(printf 'export PATH="%s:$PATH"' "$base_dir/level1")
  level2_entry=$(printf 'export PATH="%s:$PATH"' "$base_dir/level1/level2")

  run grep -Fq "$base_entry" "$HOME/.bashrc"
  assert_success
  run grep -Fq "$level1_entry" "$HOME/.bashrc"
  assert_success
  run grep -Fq "$level2_entry" "$HOME/.bashrc"
  assert_success

  run_spell 'spells/path-wizard' '-r' 'status' "$base_dir"
  assert_success

  run_spell 'spells/path-wizard' '-r' 'remove' "$base_dir"
  assert_success

  run grep -Fq "$base_entry" "$HOME/.bashrc"
  assert_failure
  run grep -Fq "$level1_entry" "$HOME/.bashrc"
  assert_failure
  run grep -Fq "$level2_entry" "$HOME/.bashrc"
  assert_failure

  run_spell 'spells/path-wizard' '-r' 'status' "$base_dir"
  assert_failure
}


@test 'path-wizard recognises existing quoted PATH lines' {
  target_dir="${BATS_TEST_TMPDIR}/quoted"
  mkdir -p "$target_dir"

  cat <<EOF >>"$HOME/.bashrc"
export PATH="${target_dir}:\$PATH"
EOF

  run_spell 'spells/path-wizard' 'status' "$target_dir"
  assert_success

  run_spell 'spells/path-wizard' 'add' "$target_dir"
  assert_success
  assert_output --partial "'$target_dir' is already exported"

  run grep -F "$target_dir" "$HOME/.bashrc"
  assert_success
  count=$(grep -F "$target_dir" "$HOME/.bashrc" | wc -l | tr -d ' ')
  [ "$count" -eq 1 ]
}

@test 'path-wizard recognises $HOME-based PATH entries' {
  rel_dir="wizardry-home"
  target_dir="$HOME/$rel_dir"
  mkdir -p "$target_dir"

  printf 'export PATH="$HOME/%s:$PATH"\n' "$rel_dir" >>"$HOME/.bashrc"

  run_spell 'spells/path-wizard' 'status' "$target_dir"
  assert_success

  run_spell 'spells/path-wizard' 'add' "$target_dir"
  assert_success
  assert_output --partial "'$target_dir' is already exported"
}

@test 'path-wizard recognises tilde PATH entries' {
  rel_dir="wizardry-tilde"
  target_dir="$HOME/$rel_dir"
  mkdir -p "$target_dir"

  printf 'export PATH="~/%s:$PATH"\n' "$rel_dir" >>"$HOME/.bashrc"

  run_spell 'spells/path-wizard' 'status' "$target_dir"
  assert_success

  run_spell 'spells/path-wizard' 'add' "$target_dir"
  assert_success
  assert_output --partial "'$target_dir' is already exported"
}

@test 'path-wizard ignores directories mentioned outside PATH assignments' {
  stray_dir="${BATS_TEST_TMPDIR}/stray"
  mkdir -p "$stray_dir"

  cat <<EOF >>"$HOME/.bashrc"
# note: $stray_dir is referenced below but not exported
alias straydir='$stray_dir'
EOF

  run_spell 'spells/path-wizard' 'status' "$stray_dir"
  assert_failure

  run_spell 'spells/path-wizard' 'add' "$stray_dir"
  assert_success
  assert_output --partial "Added '$stray_dir' to PATH via '$HOME/.bashrc'"

  entry=$(printf 'export PATH="%s:$PATH"' "$stray_dir")
  run grep -Fq "$entry" "$HOME/.bashrc"
  assert_success
}

@test 'path-wizard requires a directory when checking status' {
  run_spell 'spells/path-wizard' 'status'
  assert_failure
  assert_error --partial "expects a directory argument"
}

@test 'path-wizard supports alternate rc files' {
  target_dir="$BATS_TEST_TMPDIR/alt"
  mkdir -p "$target_dir"
  rc_file="$HOME/.zshrc"
  rm -f "$rc_file"

  run_spell 'spells/path-wizard' '--rc-file' "$rc_file" 'add' "$target_dir"
  assert_success
  assert_output --partial "Added '$target_dir' to PATH via '$rc_file'"
  alt_entry=$(printf 'export PATH="%s:$PATH"' "$target_dir")
  run grep -Fq "$alt_entry" "$rc_file"
  assert_success

  run_spell 'spells/path-wizard' '--rc-file' "$rc_file" 'remove' "$target_dir"
  assert_success
  assert_output --partial "Removed '$target_dir' from PATH entries recorded in '$rc_file'"
  run grep -Fq "$alt_entry" "$rc_file"
  assert_failure
}

@test 'path-wizard manages Nix configuration files' {
  target_dir="$BATS_TEST_TMPDIR/nix_target"
  mkdir -p "$target_dir"
  rc_file="$HOME/.config/nixpkgs/configuration.nix"
  rm -rf "$HOME/.config"

  run_spell 'spells/path-wizard' '--rc-file' "$rc_file" '--format' nix 'add' "$target_dir"
  assert_success
  assert_output --partial "Recorded '$target_dir' in '$rc_file'"
  assert_output --partial 'Rebuild your Nix environment'
  run grep -F '# wizardry PATH begin' "$rc_file"
  assert_success
  run grep -F "\"$target_dir\"" "$rc_file"
  assert_success

  run_spell 'spells/path-wizard' '--rc-file' "$rc_file" '--format' nix 'status' "$target_dir"
  assert_success

  run_spell 'spells/path-wizard' '--rc-file' "$rc_file" '--format' nix 'add' "$target_dir"
  assert_success
  assert_output --partial "'$target_dir' is already listed"

  run_spell 'spells/path-wizard' '--rc-file' "$rc_file" '--format' nix 'remove' "$target_dir"
  assert_success
  assert_output --partial "Removed '$target_dir' from '$rc_file'"
  assert_output --partial 'Rebuild your Nix environment'
  assert_error --partial 'backed up'
  run grep -F "\"$target_dir\"" "$rc_file"
  assert_failure
  run grep -F '# wizardry PATH begin' "$rc_file"
  assert_failure

  backup=$(ls "$rc_file".wizardry.* 2>/dev/null | head -n 1)
  [ -n "$backup" ]

  run cat "$backup"
  assert_success
  assert_output --partial 'wizardry PATH begin'

  run_spell 'spells/path-wizard' '--rc-file' "$rc_file" '--format' nix 'status' "$target_dir"
  assert_failure
}

@test 'path-wizard infers nix format from rc file extension' {
  target_dir="$BATS_TEST_TMPDIR/nix_auto"
  mkdir -p "$target_dir"
  rc_file="$HOME/.config/nixpkgs/configuration.nix"
  mkdir -p "${rc_file%/*}"
  cat <<'CFG' >"$rc_file"
{ config, pkgs, ... }:

{
}
CFG

  run_spell 'spells/path-wizard' '--rc-file' "$rc_file" 'add' "$target_dir"
  assert_success
  assert_output --partial 'Rebuild your Nix environment'
  run grep -F "\"$target_dir\"" "$rc_file"
  assert_success

  backup=$(ls "$rc_file".wizardry.* 2>/dev/null | head -n 1)
  [ -n "$backup" ]

  run_spell 'spells/path-wizard' '--rc-file' "$rc_file" 'status' "$target_dir"
  assert_success
}

