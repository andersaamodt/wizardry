#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  UPDATE_ALL_LOG="$BATS_TEST_TMPDIR/update-all.log"
  : >"$UPDATE_ALL_LOG"
  export UPDATE_ALL_LOG
  export NO_COLOR=1
}

@test 'update-all runs apt workflows on Debian' {
  cat <<'STUB' >"$STUB_TMPDIR/sudo"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "sudo:$*" >>"$UPDATE_ALL_LOG"
"$@"
STUB
  chmod +x "$STUB_TMPDIR/sudo"

  cat <<'STUB' >"$STUB_TMPDIR/apt-get"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "apt-get:$*" >>"$UPDATE_ALL_LOG"

case " $* " in
  *" full-upgrade"*)
    printf '%s\n' 'Reading package lists...'
    printf 'Progress: [ 10%%] upgrading core packages\r'
    printf 'Progress: [ 65%%] upgrading core packages\r'
    printf 'Progress: [100%%] upgrading core packages\r'
    printf '\n'
    ;;
  *" autoremove"*)
    printf 'Progress: [ 50%%] cleaning up\r'
    printf 'Progress: [100%%] cleaning up\r'
    printf '\n'
    ;;
  *)
    printf '%s\n' 'Hit:1 http://example.test stable InRelease'
    ;;
esac
STUB
  chmod +x "$STUB_TMPDIR/apt-get"

  WIZARDRY_UPDATE_ALL_DISTRO=debian \
    WIZARDRY_UPDATE_ALL_ASSUME_YES=1 \
    run_spell 'spells/update-all'

  assert_success
  assert_output --partial 'Detected platform: debian'
  assert_output --partial '• Refreshing apt package lists'
  assert_output --partial '  $ sudo apt-get update'
  assert_output --partial '• Installing upgrades'
  assert_output --partial '  $ sudo apt-get -o Dpkg::Progress-Fancy=1 -o Dpkg::Use-Pty=0 -y full-upgrade'
  assert_output --partial 'Progress: [100%] upgrading core packages'
  assert_output --partial '• Removing unused packages'
  assert_output --partial '  $ sudo apt-get -o Dpkg::Progress-Fancy=1 -o Dpkg::Use-Pty=0 -y autoremove'
  assert_output --partial 'Progress: [100%] cleaning up'
  assert_output --partial 'All updates complete.'

  run cat "$UPDATE_ALL_LOG"
  assert_success
  assert_output --partial 'apt-get:update'
  assert_output --partial 'apt-get:-o Dpkg::Progress-Fancy=1 -o Dpkg::Use-Pty=0 -y full-upgrade'
  assert_output --partial 'apt-get:-o Dpkg::Progress-Fancy=1 -o Dpkg::Use-Pty=0 -y autoremove'
}

@test 'update-all -v surfaces apt output on Debian' {
  cat <<'STUB' >"$STUB_TMPDIR/sudo"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "sudo:$*" >>"$UPDATE_ALL_LOG"
"$@"
STUB
  chmod +x "$STUB_TMPDIR/sudo"

  cat <<'STUB' >"$STUB_TMPDIR/apt-get"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "apt-get:$*" >>"$UPDATE_ALL_LOG"

case " $* " in
  *" full-upgrade"*)
    printf '%s\n' 'Reading package lists...'
    printf 'Progress: [ 10%%] upgrading core packages\r'
    printf 'Progress: [ 65%%] upgrading core packages\r'
    printf 'Progress: [100%%] upgrading core packages\r'
    printf '\n'
    ;;
  *" autoremove"*)
    printf 'Progress: [ 50%%] cleaning up\r'
    printf 'Progress: [100%%] cleaning up\r'
    printf '\n'
    ;;
  *)
    printf '%s\n' 'Hit:1 http://example.test stable InRelease'
    ;;
esac
STUB
  chmod +x "$STUB_TMPDIR/apt-get"

  WIZARDRY_UPDATE_ALL_DISTRO=debian \
    WIZARDRY_UPDATE_ALL_ASSUME_YES=1 \
    run_spell 'spells/update-all' -v

  assert_success
  assert_output --partial 'Detected platform: debian'
  assert_output --partial '• Refreshing apt package lists'
  assert_output --partial 'Hit:1 http://example.test stable InRelease'
  assert_output --partial '• Installing upgrades'
  assert_output --partial 'Reading package lists...'
  assert_output --partial 'Progress: [ 65%] upgrading core packages'
  assert_output --partial '• Removing unused packages'
  assert_output --partial 'Progress: [100%] cleaning up'
  assert_output --partial 'All updates complete.'

  run cat "$UPDATE_ALL_LOG"
  assert_success
  assert_output --partial 'apt-get:update'
  assert_output --partial 'apt-get:-o Dpkg::Progress-Fancy=1 -o Dpkg::Use-Pty=0 -y full-upgrade'
  assert_output --partial 'apt-get:-o Dpkg::Progress-Fancy=1 -o Dpkg::Use-Pty=0 -y autoremove'
}

@test 'update-all refreshes pacman and pamac on Arch' {
  cat <<'STUB' >"$STUB_TMPDIR/sudo"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "sudo:$*" >>"$UPDATE_ALL_LOG"
"$@"
STUB
  chmod +x "$STUB_TMPDIR/sudo"

  cat <<'STUB' >"$STUB_TMPDIR/pacman"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "pacman:$*" >>"$UPDATE_ALL_LOG"
printf '%s\n' 'PACMAN OUTPUT'
STUB
  chmod +x "$STUB_TMPDIR/pacman"

  cat <<'STUB' >"$STUB_TMPDIR/pamac"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "pamac:$*" >>"$UPDATE_ALL_LOG"
printf '%s\n' 'PAMAC OUTPUT'
STUB
  chmod +x "$STUB_TMPDIR/pamac"

  WIZARDRY_UPDATE_ALL_DISTRO=arch \
    WIZARDRY_UPDATE_ALL_ASSUME_YES=1 \
    run_spell 'spells/update-all'

  assert_success
  assert_output --partial 'Detected platform: arch'
  assert_output --partial '• Synchronising pacman packages'
  assert_output --partial '  $ sudo pacman -Syu --noconfirm'
  assert_output --partial '• Refreshing Pamac-managed packages'
  assert_output --partial '  $ pamac update --no-confirm'
  assert_output --partial '• Rebuilding Pamac AUR packages'
  assert_output --partial '  $ pamac build --no-confirm'
  [[ "$output" != *'PACMAN OUTPUT'* ]]
  [[ "$output" != *'PAMAC OUTPUT'* ]]

  run cat "$UPDATE_ALL_LOG"
  assert_success
  assert_output --partial 'pacman:-Syu --noconfirm'
  assert_output --partial 'pamac:update --no-confirm'
  assert_output --partial 'pamac:build --no-confirm'
}

@test 'update-all updates system and user environments on NixOS' {
  cat <<'STUB' >"$STUB_TMPDIR/sudo"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "sudo:$*" >>"$UPDATE_ALL_LOG"
"$@"
STUB
  chmod +x "$STUB_TMPDIR/sudo"

  cat <<'STUB' >"$STUB_TMPDIR/nix-channel"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "nix-channel:$*" >>"$UPDATE_ALL_LOG"
printf '%s\n' 'NIX CHANNEL OUTPUT'
STUB
  chmod +x "$STUB_TMPDIR/nix-channel"

  cat <<'STUB' >"$STUB_TMPDIR/nixos-rebuild"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "nixos-rebuild:$*" >>"$UPDATE_ALL_LOG"
printf '%s\n' 'NIXOS REBUILD OUTPUT'
STUB
  chmod +x "$STUB_TMPDIR/nixos-rebuild"

  cat <<'STUB' >"$STUB_TMPDIR/nix-env"
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "nix-env:$*" >>"$UPDATE_ALL_LOG"
printf '%s\n' 'NIX ENV OUTPUT'
STUB
  chmod +x "$STUB_TMPDIR/nix-env"

  WIZARDRY_UPDATE_ALL_DISTRO=nixos \
    WIZARDRY_UPDATE_ALL_ASSUME_YES=1 \
    run_spell 'spells/update-all'

  assert_success
  assert_output --partial 'Detected platform: nixos'
  assert_output --partial '• Refreshing system channels'
  assert_output --partial '  $ sudo nix-channel --update'
  assert_output --partial '• Rebuilding system configuration'
  assert_output --partial '  $ sudo nixos-rebuild switch --upgrade'
  assert_output --partial '• Refreshing user channels'
  assert_output --partial '  $ nix-channel --update'
  assert_output --partial '• Upgrading user packages'
  assert_output --partial '  $ nix-env -u --always'
  [[ "$output" != *'NIX CHANNEL OUTPUT'* ]]
  [[ "$output" != *'NIXOS REBUILD OUTPUT'* ]]
  [[ "$output" != *'NIX ENV OUTPUT'* ]]

  run cat "$UPDATE_ALL_LOG"
  assert_success
  assert_output --partial 'sudo:nix-channel --update'
  assert_output --partial 'sudo:nixos-rebuild switch --upgrade'
  assert_output --partial 'nix-channel:--update'
  assert_output --partial 'nix-env:-u --always'
}

@test 'update-all aborts when the user declines' {
  run --separate-stderr -- env WIZARDRY_UPDATE_ALL_DISTRO=debian sh -c "printf 'n\\n' | \"$ROOT_DIR/spells/update-all\""
  assert_failure
  assert_output --partial 'Detected platform: debian'
  assert_output --partial 'Proceed with system updates?'
  assert_error --partial 'cancelled by user'
}
