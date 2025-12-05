#!/bin/sh
# Behavioral cases (derived from --help):
# - detect-rc-file prints usage
# - detect-rc-file validates arguments
# - detect-rc-file reports platform, rc_file, and format choices

set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


test_help() {
  run_spell "spells/divination/detect-rc-file" --help
  assert_success && assert_error_contains "Usage: detect-rc-file"
}

test_rejects_bad_arguments() {
  run_spell "spells/divination/detect-rc-file" --platform
  assert_failure && assert_error_contains "--platform expects a value" || return 1

  run_spell "spells/divination/detect-rc-file" --unknown
  assert_failure && assert_error_contains "unknown option '--unknown'" || return 1

  run_spell "spells/divination/detect-rc-file" extra
  assert_failure && assert_error_contains "unexpected argument 'extra'" || return 1
}

test_picks_known_platform_files() {
  run_cmd env SHELL=/bin/zsh sh -c '
    mkdir -p "$HOME"
    touch "$HOME/.bash_profile" "$HOME/.profile"
    exec spells/divination/detect-rc-file --platform mac
  '
  assert_success || return 1
  assert_output_contains "platform=mac" || return 1
  assert_output_contains "rc_file=" || return 1
  assert_output_contains ".bash_profile" || return 1
  assert_output_contains "format=shell" || return 1
}

test_emits_nix_format_hint() {
  run_cmd sh -c '
    mkdir -p "$HOME/.config/nixpkgs"
    touch "$HOME/.config/nixpkgs/home.nix"
    exec spells/divination/detect-rc-file --platform nixos
  '
  assert_success || return 1
  assert_output_contains "platform=nixos" || return 1
  assert_output_contains "rc_file=" || return 1
  assert_output_contains ".config/nixpkgs/home.nix" || return 1
  assert_output_contains "format=nix" || return 1
}

test_prefers_existing_platform_file() {
  home_dir=$(make_tempdir)
  run_cmd env DETECT_RC_FILE_PLATFORM=arch HOME="$home_dir" SHELL=/bin/bash sh -c '
    touch "$HOME/.profile"
    exec spells/divination/detect-rc-file
  '

  assert_success || return 1
  assert_output_contains "platform=arch" || return 1
  assert_output_contains "rc_file=$home_dir/.profile" || return 1
  assert_output_contains "format=shell" || return 1
}

test_prefers_shell_file_when_platform_unknown() {
  home_dir=$(make_tempdir)
  run_cmd env DETECT_RC_FILE_PLATFORM=unknown HOME="$home_dir" SHELL=/bin/zsh sh -c '
    touch "$HOME/.zshrc"
    exec spells/divination/detect-rc-file
  '

  assert_success || return 1
  assert_output_contains "platform=unknown" || return 1
  assert_output_contains "rc_file=$home_dir/.zshrc" || return 1
  assert_output_contains "format=shell" || return 1
}

test_handles_missing_home() {
  run_cmd env DETECT_RC_FILE_PLATFORM=unknown HOME= SHELL=sh sh -c '
    exec spells/divination/detect-rc-file
  '

  assert_success || return 1
  assert_output_contains "platform=unknown" || return 1
  assert_output_contains "rc_file=/.profile" || return 1
  assert_output_contains "format=shell" || return 1
}

test_nixos_falls_back_to_shell_rc() {
  # On NixOS without home-manager and without existing nix config,
  # detect-rc-file should fall back to shell RC files
  home_dir=$(make_tempdir)
  run_cmd env DETECT_RC_FILE_PLATFORM=nixos HOME="$home_dir" SHELL=/bin/bash sh -c '
    # No nix config files exist (e.g. /etc/nixos/configuration.nix or ~/.config/nixpkgs/home.nix)
    # No home-manager in PATH
    exec spells/divination/detect-rc-file
  '

  assert_success || return 1
  assert_output_contains "platform=nixos" || return 1
  assert_output_contains "rc_file=$home_dir/.bashrc" || return 1
  assert_output_contains "format=shell" || return 1
}

test_nixos_detects_new_home_manager_path() {
  # On NixOS with the newer home-manager path ~/.config/home-manager/home.nix
  home_dir=$(make_tempdir)
  run_cmd env DETECT_RC_FILE_PLATFORM=nixos HOME="$home_dir" SHELL=/bin/bash sh -c '
    mkdir -p "$HOME/.config/home-manager"
    touch "$HOME/.config/home-manager/home.nix"
    exec spells/divination/detect-rc-file
  '

  assert_success || return 1
  assert_output_contains "platform=nixos" || return 1
  assert_output_contains "rc_file=$home_dir/.config/home-manager/home.nix" || return 1
  assert_output_contains "format=nix" || return 1
}

test_nixos_respects_nixos_config_env() {
  # On NixOS, NIXOS_CONFIG env var should take precedence
  config_dir=$(make_tempdir)
  mkdir -p "$config_dir"
  touch "$config_dir/my-config.nix"
  run_cmd env DETECT_RC_FILE_PLATFORM=nixos NIXOS_CONFIG="$config_dir/my-config.nix" SHELL=/bin/bash sh -c '
    exec spells/divination/detect-rc-file
  '

  assert_success || return 1
  assert_output_contains "platform=nixos" || return 1
  assert_output_contains "rc_file=$config_dir/my-config.nix" || return 1
  assert_output_contains "format=nix" || return 1
}

test_nixos_prefers_home_manager_over_system_config() {
  # When home-manager is installed, it should be preferred over /etc/nixos/configuration.nix
  # even if the system configuration exists
  home_dir=$(make_tempdir)
  hm_stub_dir=$(make_tempdir)
  # Create a stub home-manager command
  cat >"$hm_stub_dir/home-manager" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$hm_stub_dir/home-manager"

  run_cmd env DETECT_RC_FILE_PLATFORM=nixos HOME="$home_dir" PATH="$hm_stub_dir:$PATH" SHELL=/bin/bash sh -c '
    # Create the home-manager config
    mkdir -p "$HOME/.config/home-manager"
    touch "$HOME/.config/home-manager/home.nix"
    exec spells/divination/detect-rc-file
  '

  assert_success || return 1
  assert_output_contains "platform=nixos" || return 1
  assert_output_contains "rc_file=$home_dir/.config/home-manager/home.nix" || return 1
  assert_output_contains "format=nix" || return 1
}

test_nixos_uses_system_config_without_home_manager() {
  # When home-manager is NOT installed, /etc/nixos/configuration.nix should be used
  # This test simulates a NixOS system without home-manager
  home_dir=$(make_tempdir)
  # Create a fake /etc/nixos/configuration.nix scenario by using NIXOS_CONFIG
  config_dir=$(make_tempdir)
  touch "$config_dir/configuration.nix"

  run_cmd env DETECT_RC_FILE_PLATFORM=nixos HOME="$home_dir" NIXOS_CONFIG="$config_dir/configuration.nix" SHELL=/bin/bash sh -c '
    # Ensure home-manager is not in PATH (use restricted PATH)
    PATH=/usr/bin:/bin
    export PATH
    exec spells/divination/detect-rc-file
  '

  assert_success || return 1
  assert_output_contains "platform=nixos" || return 1
  assert_output_contains "rc_file=$config_dir/configuration.nix" || return 1
  assert_output_contains "format=nix" || return 1
}

run_test_case "detect-rc-file prints usage" test_help
run_test_case "detect-rc-file validates arguments" test_rejects_bad_arguments
run_test_case "detect-rc-file picks preferred files for platform" test_picks_known_platform_files
run_test_case "detect-rc-file emits nix formatting hints" test_emits_nix_format_hint
run_test_case "detect-rc-file favors existing platform candidates" test_prefers_existing_platform_file
run_test_case "detect-rc-file respects shell defaults on unknown platforms" test_prefers_shell_file_when_platform_unknown
run_test_case "detect-rc-file tolerates missing HOME" test_handles_missing_home
run_test_case "detect-rc-file falls back to shell on NixOS without home-manager" test_nixos_falls_back_to_shell_rc
run_test_case "detect-rc-file detects new home-manager path" test_nixos_detects_new_home_manager_path
run_test_case "detect-rc-file respects NIXOS_CONFIG env var" test_nixos_respects_nixos_config_env
run_test_case "detect-rc-file prefers home-manager over system config" test_nixos_prefers_home_manager_over_system_config
run_test_case "detect-rc-file uses system config without home-manager" test_nixos_uses_system_config_without_home_manager
finish_tests
