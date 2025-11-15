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
  run grep -Fqx "export PATH=$dir:\$PATH" "$rc_file"
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
    count=$(grep -F "export PATH=$dir:\$PATH" "$HOME/.bashrc" | wc -l | tr -d ' ')
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

@test 'install falls back to bashrc on NixOS when missing' {
  rm -f "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"

  WIZARDRY_INSTALL_ASSUME_YES=1 \
    WIZARDRY_INSTALL_PLATFORM=nixos \
    run_spell 'install'

  assert_success
  assert_output --partial 'via .bashrc'
  [ -f "$HOME/.bashrc" ]

  dir="$ROOT_DIR/spells"
  rc_entries_present "$HOME/.bashrc" "$dir"
  assert_success
}
