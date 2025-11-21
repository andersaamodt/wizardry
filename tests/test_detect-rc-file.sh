#!/bin/sh
# Behavioral cases (derived from --help):
# - detect-rc-file prints usage
# - detect-rc-file validates arguments
# - detect-rc-file reports platform, rc_file, and format choices

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/detect-rc-file" --help
  assert_success && assert_error_contains "Usage: detect-rc-file"
}

test_rejects_bad_arguments() {
  run_spell "spells/detect-rc-file" --platform
  assert_failure && assert_error_contains "--platform expects a value" || return 1

  run_spell "spells/detect-rc-file" --unknown
  assert_failure && assert_error_contains "unknown option '--unknown'" || return 1

  run_spell "spells/detect-rc-file" extra
  assert_failure && assert_error_contains "unexpected argument 'extra'" || return 1
}

test_picks_known_platform_files() {
  run_cmd env SHELL=/bin/zsh sh -c '
    mkdir -p "$HOME"
    touch "$HOME/.bash_profile" "$HOME/.profile"
    exec spells/detect-rc-file --platform mac
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
    touch "$HOME/.config/nixpkgs/configuration.nix"
    exec spells/detect-rc-file --platform nixos
  '
  assert_success || return 1
  assert_output_contains "platform=nixos" || return 1
  assert_output_contains "rc_file=" || return 1
  assert_output_contains ".config/nixpkgs/configuration.nix" || return 1
  assert_output_contains "format=nix" || return 1
}

run_test_case "detect-rc-file prints usage" test_help
run_test_case "detect-rc-file validates arguments" test_rejects_bad_arguments
run_test_case "detect-rc-file picks preferred files for platform" test_picks_known_platform_files
run_test_case "detect-rc-file emits nix formatting hints" test_emits_nix_format_hint
finish_tests
