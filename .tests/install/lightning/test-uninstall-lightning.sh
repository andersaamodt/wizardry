#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/lightning/uninstall-lightning" ]
}
run_test_case "install/lightning/uninstall-lightning is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/lightning/uninstall-lightning" ]
}
run_test_case "install/lightning/uninstall-lightning has content" spell_has_content

shows_usage_help() {
  run_spell spells/install/lightning/uninstall-lightning --help
  assert_success || return 1
  assert_error_contains "Usage: uninstall-lightning"
}
run_test_case "uninstall-lightning shows usage help" shows_usage_help

removes_via_apt_on_debian() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/uninstall-lightning.XXXXXX")
  mkdir -p "$tmpdir/bin"
  log="$tmpdir/log"

  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'debian'
STUB
  cat >"$tmpdir/bin/sudo" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" >>"${APT_LOG:?}"
STUB
  cat >"$tmpdir/bin/apt-get" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"${APT_LOG:?}"
STUB
  cat >"$tmpdir/bin/lightning-cli" <<'STUB'
#!/bin/sh
exit 1
STUB
  chmod +x "$tmpdir/bin"/*

  APT_LOG="$log" PATH="$tmpdir/bin:$PATH" run_spell spells/install/lightning/uninstall-lightning
  assert_success || return 1
  assert_file_contains "$log" "apt-get remove -y lightningd"
  assert_output_contains "Lightning may still be present"
}
run_test_case "uninstall-lightning removes packages on debian" removes_via_apt_on_debian

removes_nixos_configuration_and_rebuilds() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/uninstall-lightning-nixos.XXXXXX")
  mkdir -p "$tmpdir/bin"
  config="$tmpdir/configuration.nix"
  target_config="/etc/nixos/configuration.nix"
  cat >"$config" <<'NIX'
{ environment.systemPackages = with pkgs; [
  clightning
]; }
NIX

  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'nixos'
STUB
  cat >"$tmpdir/bin/sudo" <<'STUB'
#!/bin/sh
if [ "$1" = "sed" ]; then
  shift
  sed "$@"
elif [ "$1" = "nixos-rebuild" ]; then
  printf 'rebuild\n' >>"${NIX_LOG:?}"
else
  exec "$@"
fi
STUB
  cat >"$tmpdir/bin/backup-nix-config" <<'STUB'
#!/bin/sh
printf 'backup %s\n' "$1" >>"${NIX_LOG:?}"
STUB
  cat >"$tmpdir/bin/nix-env" <<'STUB'
#!/bin/sh
printf 'nix-env %s\n' "$*" >>"${NIX_LOG:?}"
STUB
  chmod +x "$tmpdir/bin"/*

  created_config=0
  if [ ! -d "$(dirname "$target_config")" ]; then
    mkdir -p "$(dirname "$target_config")"
    created_config=1
  fi
  if [ ! -f "$target_config" ]; then
    cp "$config" "$target_config"
    created_config=1
  fi

  NIX_LOG="$tmpdir/log" PATH="$tmpdir/bin:$PATH" run_spell spells/install/lightning/uninstall-lightning "$config"

  assert_success || return 1
  if grep -q "clightning" "$target_config"; then
    printf 'found clightning in config after removal' >&2
    return 1
  fi
  assert_file_contains "$tmpdir/log" "backup"
  assert_file_contains "$tmpdir/log" "rebuild"
  assert_file_contains "$tmpdir/log" "nix-env -e clightning"
  assert_output_contains "Lightning has been removed"

  if [ "$created_config" -eq 1 ]; then
    rm -f "$target_config"
    rmdir "$(dirname "$target_config")" 2>/dev/null || true
  fi
}
run_test_case "uninstall-lightning cleans up nixos config" removes_nixos_configuration_and_rebuilds

warns_on_unsupported_platform() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/uninstall-lightning-unsupported.XXXXXX")
  mkdir -p "$tmpdir/bin"

  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'plan9'
STUB
  chmod +x "$tmpdir/bin"/*

  PATH="$tmpdir/bin:$PATH" run_spell spells/install/lightning/uninstall-lightning
  assert_success || return 1
  assert_output_contains "Unsupported distribution"
}
run_test_case "uninstall-lightning warns on unsupported distro" warns_on_unsupported_platform

finish_tests
