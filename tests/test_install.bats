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
  local pattern_plain pattern_plain_quoted pattern_escaped pattern_escaped_quoted
  pattern_plain=$(printf 'export PATH=%s:$PATH' "$dir")
  pattern_plain_quoted=$(printf 'export PATH="%s:$PATH"' "$dir")
  pattern_escaped=$(printf 'export PATH=%s:\\$PATH' "$dir")
  pattern_escaped_quoted=$(printf 'export PATH="%s:\\$PATH"' "$dir")

  run sh -c '
    p1=$1
    p2=$2
    p3=$3
    p4=$4
    file=$5
    if grep -Fq "$p1" "$file"; then exit 0; fi
    if grep -Fq "$p2" "$file"; then exit 0; fi
    if grep -Fq "$p3" "$file"; then exit 0; fi
    grep -Fq "$p4" "$file"
  ' sh \
    "$pattern_plain" \
    "$pattern_plain_quoted" \
    "$pattern_escaped" \
    "$pattern_escaped_quoted" \
    "$rc_file"
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

  SHELL=/bin/sh \
    WIZARDRY_INSTALL_ASSUME_YES=1 \
    WIZARDRY_INSTALL_DIR="$ROOT_DIR" \
    run_spell 'install'
  assert_success
  assert_output --partial 'ao-mud will ensure'
  assert_output --partial 'Your spellbook has been activated'
  if [[ "$output" == *"Skipping"* ]] || [[ "$stderr" == *"Skipping"* ]]; then
    fail 'install output included memorize skip warnings'
  fi

  for rel in spells spells/cantrips spells/menu; do
    dir="$ROOT_DIR/$rel"
    rc_entries_present "$HOME/.bashrc" "$dir"
    assert_success
  done

  # Re-run to confirm the installer exits early without duplicating entries.
  SHELL=/bin/sh \
    WIZARDRY_INSTALL_ASSUME_YES=1 \
    WIZARDRY_INSTALL_DIR="$ROOT_DIR" \
    run_spell 'install'
  assert_success
  assert_output --partial 'already installed'

  for rel in spells spells/cantrips spells/menu; do
    dir="$ROOT_DIR/$rel"
    pattern=$(printf 'export PATH="%s:$PATH"' "$dir")
    count=$(grep -F "$pattern" "$HOME/.bashrc" | wc -l | tr -d ' ')
    [ "$count" -eq 1 ]
  done
}

@test 'install copies the local checkout instead of downloading' {
  cat <<'RC' >"$HOME/.bashrc"
# local copy shell config
RC

  target="$BATS_TEST_TMPDIR/copied"
  rm -rf "$target"

  wizardry_stub curl 'exit 1'
  wizardry_stub wget 'exit 1'

  SHELL=/bin/sh \
    WIZARDRY_INSTALL_ASSUME_YES=1 \
    WIZARDRY_INSTALL_DIR="$target" \
    run_spell 'install'

  assert_success
  [ -d "$target/spells" ]

  run cmp "$ROOT_DIR/install" "$target/install"
  assert_success
}


@test 'install skips directories already referenced with quotes' {
  cat <<EOF >"$HOME/.bashrc"
export PATH="$ROOT_DIR/spells:\$PATH"
export PATH="$ROOT_DIR/spells/cantrips:\$PATH"
export PATH="$ROOT_DIR/spells/menu:\$PATH"
EOF

  SHELL=/bin/sh \
    WIZARDRY_INSTALL_ASSUME_YES=1 \
    WIZARDRY_INSTALL_DIR="$ROOT_DIR" \
    run_spell 'install'
  assert_success
  assert_output --partial 'already installed'

  for rel in spells spells/cantrips spells/menu; do
    dir="$ROOT_DIR/$rel"
    pattern=$(printf 'export PATH="%s:$PATH"' "$dir")
    count=$(grep -F "$pattern" "$HOME/.bashrc" | wc -l | tr -d ' ')
    [ "$count" -eq 1 ]
  done
}

@test 'install selects zsh configuration on macOS' {
  rm -f "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"

  SHELL=/bin/sh \
    WIZARDRY_INSTALL_ASSUME_YES=1 \
    WIZARDRY_INSTALL_PLATFORM=mac \
    WIZARDRY_INSTALL_DIR="$ROOT_DIR" \
    run_spell 'install'

  assert_success
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

  run --separate-stderr -- env ROOT_DIR="$ROOT_DIR" \
    SHELL=/bin/sh \
    WIZARDRY_INSTALL_ASSUME_YES=1 \
    WIZARDRY_INSTALL_PLATFORM=nixos \
    WIZARDRY_INSTALL_DIR="$ROOT_DIR" \
    ASK_CANTRIP_INPUT=stdin \
    sh -c "printf 'y\\n' | \"\$ROOT_DIR/install\""

  assert_success

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

}

@test 'install aborts when the user declines on NixOS' {
  mkdir -p "$HOME/.config/nixpkgs"
  rc_file="$HOME/.config/nixpkgs/configuration.nix"
  cat <<'CFG' >"$rc_file"
{ config, pkgs, ... }:

{
  environment.sessionVariables.PATH = "original";
}
CFG

  run --separate-stderr -- env ROOT_DIR="$ROOT_DIR" \
    SHELL=/bin/sh \
    WIZARDRY_INSTALL_PLATFORM=nixos \
    WIZARDRY_INSTALL_DIR="$ROOT_DIR" \
    ASK_CANTRIP_INPUT=stdin \
    sh -c "printf 'n\\n' | \"\$ROOT_DIR/install\""

  assert_failure
  assert_error --partial 'Proceed with installation?'
  run grep -F 'original' "$rc_file"
  assert_success
  run ls "$rc_file".wizardry.*
  assert_failure
}

@test 'install accepts defaults when stdin is redirected' {
  cat <<'RC' >"$HOME/.bashrc"
# default shell config
RC

  run --separate-stderr -- env \
    ROOT_DIR="$ROOT_DIR" \
    SHELL=/bin/sh \
    HOME="$HOME" \
    WIZARDRY_INSTALL_DIR="$ROOT_DIR" \
    sh -c '"$ROOT_DIR/install" </dev/null'

  assert_success
  assert_output --partial 'Your spellbook has been activated'
  assert_error --partial 'Proceed with installation?'
}

@test 'install prompt accepts interactive input when stdin is a tty' {
  if ! command -v python3 >/dev/null 2>&1; then
    skip 'python3 is required to emulate a tty'
  fi

  cat <<'RC' >"$HOME/.bashrc"
# prompt test shell config
RC

  local pty_input
  pty_input="$ROOT_DIR"$'\n'

  run --separate-stderr -- env \
    ROOT_DIR="$ROOT_DIR" \
    TEST_DIR="$ROOT_DIR/tests" \
    HOME="$HOME" \
    SHELL=/bin/sh \
    WIZARDRY_INSTALL_ASSUME_YES=1 \
    WIZARDRY_PTY_INPUT="$pty_input" \
    python3 "$ROOT_DIR/tests/lib/run_with_pty.py" \
    "$ROOT_DIR/tests/lib/run_with_coverage.sh" install

  assert_success
  assert_output --partial 'Where should wizardry be installed?'

  run grep -F 'Where should wizardry be installed' "$HOME/.bashrc"
  assert_failure
}
