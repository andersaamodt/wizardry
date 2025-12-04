#!/bin/sh
set -eu

# Locate test root to source helpers
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/lightning/install-lightning" ]
}
run_test_case "install/lightning/install-lightning is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/lightning/install-lightning" ]
}
run_test_case "install/lightning/install-lightning has content" spell_has_content

shows_usage_help() {
  run_spell spells/install/lightning/install-lightning --help
  assert_success || return 1
  assert_error_contains "Usage: install-lightning"
}
run_test_case "install-lightning shows usage help" shows_usage_help

installs_via_apt_on_debian() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/lightning-apt.XXXXXX")
  mkdir -p "$tmpdir/bin"
  log="$tmpdir/log"

  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'debian'
STUB
  cat >"$tmpdir/bin/apt-get" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"${APT_LOG:?}"
STUB
  cat >"$tmpdir/bin/sudo" <<'STUB'
#!/bin/sh
exec "$@"
STUB
  chmod +x "$tmpdir/bin"/*

  runner="$tmpdir/run-apt"
  cat >"$runner" <<EOF
#!/bin/sh
PATH="$tmpdir/bin:/usr/bin:/bin"
APT_LOG="$log"
export PATH APT_LOG
"$ROOT_DIR"/spells/install/lightning/install-lightning
EOF
  chmod +x "$runner"

  out_file="$tmpdir/output"
  err_file="$tmpdir/error"
  STATUS=0
  if "$runner" >"$out_file" 2>"$err_file"; then STATUS=0; else STATUS=$?; fi
  OUTPUT=$(cat "$out_file")
  ERROR=$(cat "$err_file")

  assert_success || return 1
  assert_file_contains "$log" "update"
  assert_file_contains "$log" "install -y lightningd"
}
run_test_case "install-lightning installs with apt on debian" installs_via_apt_on_debian

adds_lightning_to_nixos_config() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/lightning-nixos.XXXXXX")
  mkdir -p "$tmpdir/bin"
  config="$tmpdir/configuration.nix"
  target_config="/etc/nixos/configuration.nix"
  cat >"$config" <<'NIX'
{
  environment.systemPackages = with pkgs; [
  ];
}
NIX

  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'nixos'
STUB
  cat >"$tmpdir/bin/backup-nix-config" <<'STUB'
#!/bin/sh
printf 'backup %s\n' "$1" >>"${NIX_LOG:?}"
STUB
  cat >"$tmpdir/bin/sudo" <<'STUB'
#!/bin/sh
if [ "$1" = "perl" ]; then
  shift
  perl "$@"
elif [ "$1" = "tee" ]; then
  shift
  tee "$@"
elif [ "$1" = "nixos-rebuild" ]; then
  printf 'rebuild\n' >>"${NIX_LOG:?}"
else
  exec "$@"
fi
STUB
  chmod +x "$tmpdir/bin"/*

  runner="$tmpdir/run-nixos"
  cat >"$runner" <<EOF
#!/bin/sh
PATH="$tmpdir/bin:/usr/bin:/bin"
NIX_LOG="$tmpdir/log"
export PATH NIX_LOG
printf '%s\n' "$config" | "$ROOT_DIR"/spells/install/lightning/install-lightning
EOF
  chmod +x "$runner"

  created_config=0
  if [ ! -d "$(dirname "$target_config")" ]; then
    mkdir -p "$(dirname "$target_config")"
    created_config=1
  fi
  if [ ! -f "$target_config" ]; then
    cp "$config" "$target_config"
    created_config=1
  fi

  if ! "$runner" >"$tmpdir/output" 2>"$tmpdir/error"; then
    STATUS=$?
  else
    STATUS=0
  fi
  OUTPUT=$(cat "$tmpdir/output")
  ERROR=$(cat "$tmpdir/error")

  assert_success || return 1
  assert_file_contains "$target_config" "clightning"
  assert_file_contains "$tmpdir/log" "backup"
  assert_file_contains "$tmpdir/log" "rebuild"
  assert_output_contains "Lightning installation attempted"

  if [ "$created_config" -eq 1 ]; then
    rm -f "$target_config"
    rmdir "$(dirname "$target_config")" 2>/dev/null || true
  fi
}
run_test_case "install-lightning updates nixos configuration" adds_lightning_to_nixos_config

installs_via_pacman_on_arch() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/lightning-arch.XXXXXX")
  mkdir -p "$tmpdir/bin"
  log="$tmpdir/log"

  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'arch'
STUB
  cat >"$tmpdir/bin/pacman" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"${PACMAN_LOG:?}"
STUB
  cat >"$tmpdir/bin/sudo" <<'STUB'
#!/bin/sh
exec "$@"
STUB
  cat >"$tmpdir/bin/lightning-cli" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$tmpdir/bin"/*

  PACMAN_LOG="$log" PATH="$tmpdir/bin:$PATH" run_spell spells/install/lightning/install-lightning
  assert_success || return 1
  assert_file_contains "$log" "-Sy --noconfirm lightningd"
  assert_output_contains "Lightning installation complete"
}
run_test_case "install-lightning installs with pacman on arch" installs_via_pacman_on_arch

fails_when_homebrew_absent_on_mac() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/lightning-mac.XXXXXX")
  mkdir -p "$tmpdir/bin"

  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'mac'
STUB
  chmod +x "$tmpdir/bin"/*

  PATH="$tmpdir/bin:$PATH" run_spell spells/install/lightning/install-lightning
  assert_failure || return 1
  assert_output_contains "Homebrew is required"
}
run_test_case "install-lightning requires brew on mac" fails_when_homebrew_absent_on_mac

finish_tests
