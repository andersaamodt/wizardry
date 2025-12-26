#!/bin/sh
# Behavioral cases (derived from --help):
# - detect-rc-file prints usage
# - detect-rc-file validates arguments
# - detect-rc-file reports platform, rc_file, and format choices

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/divination/detect-rc-file" --help
  _assert_success && _assert_error_contains "Usage: detect-rc-file"
}

test_rejects_bad_arguments() {
  _run_spell "spells/divination/detect-rc-file" --platform
  _assert_failure && _assert_error_contains "Usage: detect-rc-file" || return 1

  _run_spell "spells/divination/detect-rc-file" --unknown
  _assert_failure && _assert_error_contains "Usage: detect-rc-file" || return 1

  _run_spell "spells/divination/detect-rc-file" extra
  _assert_failure && _assert_error_contains "Usage: detect-rc-file" || return 1
}

test_picks_known_platform_files() {
  _run_cmd env SHELL=/bin/zsh sh -c '
    mkdir -p "$HOME"
    touch "$HOME/.bash_profile" "$HOME/.profile"
    exec spells/divination/detect-rc-file --platform mac
  '
  _assert_success || return 1
  _assert_output_contains "platform=mac" || return 1
  _assert_output_contains "rc_file=" || return 1
  _assert_output_contains ".bash_profile" || return 1
  _assert_output_contains "format=shell" || return 1
}

test_emits_nix_format_hint() {
  _run_cmd sh -c '
    mkdir -p "$HOME/.config/nixpkgs"
    touch "$HOME/.config/nixpkgs/home.nix"
    exec spells/divination/detect-rc-file --platform nixos
  '
  _assert_success || return 1
  _assert_output_contains "platform=nixos" || return 1
  _assert_output_contains "rc_file=" || return 1
  _assert_output_contains ".config/nixpkgs/home.nix" || return 1
  _assert_output_contains "format=nix" || return 1
}

test_prefers_existing_platform_file() {
  home_dir=$(_make_tempdir)
  _run_cmd env DETECT_RC_FILE_PLATFORM=arch HOME="$home_dir" SHELL=/bin/bash sh -c '
    touch "$HOME/.profile"
    exec spells/divination/detect-rc-file
  '

  _assert_success || return 1
  _assert_output_contains "platform=arch" || return 1
  _assert_output_contains "rc_file=$home_dir/.profile" || return 1
  _assert_output_contains "format=shell" || return 1
}

test_prefers_shell_file_when_platform_unknown() {
  home_dir=$(_make_tempdir)
  _run_cmd env DETECT_RC_FILE_PLATFORM=unknown HOME="$home_dir" SHELL=/bin/zsh sh -c '
    touch "$HOME/.zshrc"
    exec spells/divination/detect-rc-file
  '

  _assert_success || return 1
  _assert_output_contains "platform=unknown" || return 1
  _assert_output_contains "rc_file=$home_dir/.zshrc" || return 1
  _assert_output_contains "format=shell" || return 1
}

test_handles_missing_home() {
  _run_cmd env DETECT_RC_FILE_PLATFORM=unknown HOME= SHELL=sh sh -c '
    exec spells/divination/detect-rc-file
  '

  _assert_success || return 1
  _assert_output_contains "platform=unknown" || return 1
  _assert_output_contains "rc_file=/.profile" || return 1
  _assert_output_contains "format=shell" || return 1
}

test_nixos_falls_back_to_shell_rc() {
  # On NixOS without home-manager and without existing nix config,
  # detect-rc-file should fall back to shell RC files
  home_dir=$(_make_tempdir)
  _run_cmd env DETECT_RC_FILE_PLATFORM=nixos HOME="$home_dir" SHELL=/bin/bash sh -c '
    # No nix config files exist (e.g. /etc/nixos/configuration.nix or ~/.config/nixpkgs/home.nix)
    # No home-manager in PATH
    exec spells/divination/detect-rc-file
  '

  _assert_success || return 1
  _assert_output_contains "platform=nixos" || return 1
  _assert_output_contains "rc_file=$home_dir/.bashrc" || return 1
  _assert_output_contains "format=shell" || return 1
}

test_nixos_detects_new_home_manager_path() {
  # On NixOS with the newer home-manager path ~/.config/home-manager/home.nix
  home_dir=$(_make_tempdir)
  _run_cmd env DETECT_RC_FILE_PLATFORM=nixos HOME="$home_dir" SHELL=/bin/bash sh -c '
    mkdir -p "$HOME/.config/home-manager"
    touch "$HOME/.config/home-manager/home.nix"
    exec spells/divination/detect-rc-file
  '

  _assert_success || return 1
  _assert_output_contains "platform=nixos" || return 1
  _assert_output_contains "rc_file=$home_dir/.config/home-manager/home.nix" || return 1
  _assert_output_contains "format=nix" || return 1
}

test_nixos_respects_nixos_config_env() {
  # On NixOS, NIXOS_CONFIG env var should take precedence
  config_dir=$(_make_tempdir)
  mkdir -p "$config_dir"
  touch "$config_dir/my-config.nix"
  _run_cmd env DETECT_RC_FILE_PLATFORM=nixos NIXOS_CONFIG="$config_dir/my-config.nix" SHELL=/bin/bash sh -c '
    exec spells/divination/detect-rc-file
  '

  _assert_success || return 1
  _assert_output_contains "platform=nixos" || return 1
  _assert_output_contains "rc_file=$config_dir/my-config.nix" || return 1
  _assert_output_contains "format=nix" || return 1
}

test_nixos_prefers_home_manager_over_system_config() {
  # When home-manager is installed, it should be preferred over /etc/nixos/configuration.nix
  # even if the system configuration exists
  home_dir=$(_make_tempdir)
  hm_stub_dir=$(_make_tempdir)
  # Create a stub home-manager command
  cat >"$hm_stub_dir/home-manager" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$hm_stub_dir/home-manager"

  _run_cmd env DETECT_RC_FILE_PLATFORM=nixos HOME="$home_dir" PATH="$hm_stub_dir:$PATH" SHELL=/bin/bash sh -c '
    # Create the home-manager config
    mkdir -p "$HOME/.config/home-manager"
    touch "$HOME/.config/home-manager/home.nix"
    exec spells/divination/detect-rc-file
  '

  _assert_success || return 1
  _assert_output_contains "platform=nixos" || return 1
  _assert_output_contains "rc_file=$home_dir/.config/home-manager/home.nix" || return 1
  _assert_output_contains "format=nix" || return 1
}

test_nixos_uses_system_config_without_home_manager() {
  # When home-manager is NOT installed, /etc/nixos/configuration.nix should be used
  # This test simulates a NixOS system without home-manager
  home_dir=$(_make_tempdir)
  # Create a fake /etc/nixos/configuration.nix scenario by using NIXOS_CONFIG
  config_dir=$(_make_tempdir)
  touch "$config_dir/configuration.nix"

  _run_cmd env DETECT_RC_FILE_PLATFORM=nixos HOME="$home_dir" NIXOS_CONFIG="$config_dir/configuration.nix" SHELL=/bin/bash sh -c '
    # Ensure home-manager is not in PATH (use restricted PATH)
    PATH=/usr/bin:/bin
    export PATH
    exec spells/divination/detect-rc-file
  '

  _assert_success || return 1
  _assert_output_contains "platform=nixos" || return 1
  _assert_output_contains "rc_file=$config_dir/configuration.nix" || return 1
  _assert_output_contains "format=nix" || return 1
}

test_mac_prefers_zsh_over_bashrc() {
  # On macOS with zsh, even if .bashrc exists, .zprofile or .zshrc should be preferred
  # This regression test ensures generic fallbacks don't override platform-specific preferences
  home_dir=$(_make_tempdir)
  _run_cmd env DETECT_RC_FILE_PLATFORM=mac HOME="$home_dir" SHELL=/bin/zsh sh -c '
    # Create .bashrc but not .zprofile or .zshrc
    touch "$HOME/.bashrc"
    exec spells/divination/detect-rc-file
  '

  _assert_success || return 1
  _assert_output_contains "platform=mac" || return 1
  # Should prefer .zprofile (first Mac candidate) over .bashrc, even though .bashrc exists
  _assert_output_contains "rc_file=$home_dir/.zprofile" || return 1
  _assert_output_contains "format=shell" || return 1
}

test_mac_uses_existing_zshrc_over_bashrc() {
  # On macOS with zsh, if .zshrc exists and .zprofile doesn't, use .zshrc
  # even if .bashrc also exists
  home_dir=$(_make_tempdir)
  _run_cmd env DETECT_RC_FILE_PLATFORM=mac HOME="$home_dir" SHELL=/bin/zsh sh -c '
    touch "$HOME/.bashrc"
    touch "$HOME/.zshrc"
    exec spells/divination/detect-rc-file
  '

  _assert_success || return 1
  _assert_output_contains "platform=mac" || return 1
  # Should use .zshrc (exists and is higher priority) over .bashrc
  _assert_output_contains "rc_file=$home_dir/.zshrc" || return 1
  _assert_output_contains "format=shell" || return 1
}

_run_test_case "detect-rc-file prints usage" test_help
_run_test_case "detect-rc-file validates arguments" test_rejects_bad_arguments
_run_test_case "detect-rc-file picks preferred files for platform" test_picks_known_platform_files
_run_test_case "detect-rc-file emits nix formatting hints" test_emits_nix_format_hint
_run_test_case "detect-rc-file favors existing platform candidates" test_prefers_existing_platform_file
_run_test_case "detect-rc-file respects shell defaults on unknown platforms" test_prefers_shell_file_when_platform_unknown
_run_test_case "detect-rc-file tolerates missing HOME" test_handles_missing_home
_run_test_case "detect-rc-file falls back to shell on NixOS without home-manager" test_nixos_falls_back_to_shell_rc
_run_test_case "detect-rc-file detects new home-manager path" test_nixos_detects_new_home_manager_path
_run_test_case "detect-rc-file respects NIXOS_CONFIG env var" test_nixos_respects_nixos_config_env
_run_test_case "detect-rc-file prefers home-manager over system config" test_nixos_prefers_home_manager_over_system_config
_run_test_case "detect-rc-file uses system config without home-manager" test_nixos_uses_system_config_without_home_manager
_run_test_case "detect-rc-file prefers zsh files over bashrc on Mac" test_mac_prefers_zsh_over_bashrc
_run_test_case "detect-rc-file uses existing zshrc over bashrc on Mac" test_mac_uses_existing_zshrc_over_bashrc

# Test via source-then-invoke pattern  
detect_rc_file_help_via_sourcing() {
  _run_sourced_spell detect-rc-file --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "detect-rc-file works via source-then-invoke" detect_rc_file_help_via_sourcing
_finish_tests
