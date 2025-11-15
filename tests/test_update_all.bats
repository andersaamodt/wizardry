#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  UPDATE_ALL_LOG="$BATS_TEST_TMPDIR/update-all.log"
  : >"$UPDATE_ALL_LOG"
  export UPDATE_ALL_LOG
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
printf '%s\n' 'APT OUTPUT'
STUB
  chmod +x "$STUB_TMPDIR/apt-get"

  WIZARDRY_UPDATE_ALL_DISTRO=debian \
    WIZARDRY_UPDATE_ALL_ASSUME_YES=1 \
    run_spell 'spells/update-all'

  assert_success
  assert_output --partial 'Detected platform: debian'
  assert_output --partial '• Refreshing apt package lists'
  assert_output --partial 'All updates complete.'
  [[ "$output" != *'APT OUTPUT'* ]]
  [[ "$stderr" != *'APT OUTPUT'* ]]

  run cat "$UPDATE_ALL_LOG"
  assert_success
  assert_output --partial 'apt-get:update'
  assert_output --partial 'apt-get:-y full-upgrade'
  assert_output --partial 'apt-get:-y autoremove'
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
  assert_output --partial '• Refreshing Pamac-managed packages'
  assert_output --partial '• Rebuilding Pamac AUR packages'
  [[ "$output" != *'PACMAN OUTPUT'* ]]
  [[ "$output" != *'PAMAC OUTPUT'* ]]

  run cat "$UPDATE_ALL_LOG"
  assert_success
  assert_output --partial 'pacman:-Syu --noconfirm'
  assert_output --partial 'pamac:update --no-confirm'
  assert_output --partial 'pamac:build --no-confirm'
}

@test 'update-all aborts when the user declines' {
  run --separate-stderr -- env WIZARDRY_UPDATE_ALL_DISTRO=debian sh -c "printf 'n\\n' | \"$ROOT_DIR/spells/update-all\""
  assert_failure
  assert_output --partial 'Detected platform: debian'
  assert_output --partial 'Proceed with system updates?'
  assert_error --partial 'cancelled by user'
}
