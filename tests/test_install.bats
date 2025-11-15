#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_HOME=$HOME
  HOME="$BATS_TEST_TMPDIR/install_home"
  export HOME
  mkdir -p "$HOME"
}

teardown() {
  HOME=$ORIGINAL_HOME
  export HOME
  default_teardown
}

rc_entries_present() {
  local rc_file=$1
  local dir=$2
  local pattern
  pattern=$(printf 'export PATH=%s:\\$PATH' "$dir")
  run grep -Fqx "$pattern" "$rc_file"
}

nix_entries_present() {
  local rc_file=$1
  local dir=$2
  run grep -F "\"$dir\"" "$rc_file"
}

@test 'install populates bashrc and is idempotent' {
  cat <<'RC' >"$HOME/.bashrc"
# test shell config
RC

  WIZARDRY_INSTALL_ASSUME_YES=1 run_spell 'install'
  assert_success
  assert_output --partial 'ao-mud will ensure'
  assert_output --partial 'Your spellbook has been activated'

  for rel in spells spells/cantrips spells/menu; do
    dir="$ROOT_DIR/$rel"
    rc_entries_present "$HOME/.bashrc" "$dir"
    assert_success
  done

  # Re-run to confirm the installer exits early without duplicating entries.
  WIZARDRY_INSTALL_ASSUME_YES=1 run_spell 'install'
  assert_success
  assert_output --partial 'already installed'

  for rel in spells spells/cantrips spells/menu; do
    dir="$ROOT_DIR/$rel"
    pattern=$(printf 'export PATH=%s:\\$PATH' "$dir")
    count=$(grep -F "$pattern" "$HOME/.bashrc" | wc -l | tr -d ' ')
    [ "$count" -eq 1 ]
  done
}

@test 'install selects zsh configuration on macOS' {
  rm -f "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"

  WIZARDRY_INSTALL_ASSUME_YES=1 \
    WIZARDRY_INSTALL_PLATFORM=mac \
    run_spell 'install'

  assert_success
  assert_output --partial 'via .zshrc'

  rc_file="$HOME/.zshrc"
  [ -f "$rc_file" ]

  for rel in spells spells/cantrips spells/menu; do
    dir="$ROOT_DIR/$rel"
    rc_entries_present "$rc_file" "$dir"
    assert_success
  done
}

@test 'install writes to configuration.nix on NixOS' {
  rm -rf "$HOME/.config" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"

  mkdir -p "$HOME/.config/nixpkgs"
  cat <<'CFG' >"$HOME/.config/nixpkgs/configuration.nix"
# existing config
{ config, pkgs, ... }:

{
  environment.sessionVariables.PATH = "original";
}
CFG

  run --separate-stderr -- env ROOT_DIR="$ROOT_DIR" WIZARDRY_INSTALL_ASSUME_YES=1 WIZARDRY_INSTALL_PLATFORM=nixos \
    sh -c "printf 'y\\n' | \"\$ROOT_DIR/install\""

  assert_success
  assert_output --partial 'via configuration.nix'
  assert_output --partial 'Rebuild your Nix environment'
  assert_output --partial 'NixOS detected:'

  rc_file="$HOME/.config/nixpkgs/configuration.nix"
  [ -f "$rc_file" ]

  backup=$(ls "$rc_file".wizardry.* 2>/dev/null | head -n 1)
  [ -n "$backup" ]

  run cat "$backup"
  assert_success
  assert_output --partial '# existing config'

  for rel in spells spells/cantrips spells/menu; do
    dir="$ROOT_DIR/$rel"
    nix_entries_present "$rc_file" "$dir"
    assert_success
  done

  assert_error --partial 'backed up'
}
