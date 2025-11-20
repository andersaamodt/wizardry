#!/bin/sh
# Behavioral cases (derived from --help):
# - detect-distro shows usage with --help
# - detect-distro rejects unexpected arguments
# - detect-distro prints the detected identifier
# - detect-distro narrates with -v

set -eu

. "$(dirname "$0")/lib/test_common.sh"

expected_distro() {
  if [ -f /etc/NIXOS ] || grep -i 'ID=nixos' /etc/os-release >/dev/null 2>&1; then
    printf 'nixos'
  elif [ -f /etc/debian_version ]; then
    printf 'debian'
  elif [ -f /etc/arch-release ]; then
    printf 'arch'
  elif [ -f /etc/fedora-release ]; then
    printf 'fedora'
  elif uname >/dev/null 2>&1 && [ "$(uname)" = "Darwin" ]; then
    printf 'mac'
  else
    printf 'unknown'
  fi
}

shows_usage_on_help() {
  run_spell "spells/detect-distro" "--help"
  assert_success || return 1
  assert_output_contains "Usage: detect-distro" || return 1
}

rejects_unexpected_arguments() {
  run_spell "spells/detect-distro" "extra"
  assert_failure || return 1
  assert_error_contains "Usage: detect-distro" || return 1
}

prints_detected_identifier() {
  expected=$(expected_distro)
  run_spell "spells/detect-distro"
  if [ "$expected" = "unknown" ]; then
    assert_failure || return 1
    assert_output_contains "unknown" || return 1
  else
    assert_success || return 1
    [ "$OUTPUT" = "$expected" ] || { TEST_FAILURE_REASON="expected '$expected' but saw '$OUTPUT'"; return 1; }
  fi
}

verbose_mode_narrates() {
  expected=$(expected_distro)
  run_spell "spells/detect-distro" "-v"
  if [ "$expected" = "unknown" ]; then
    assert_failure || return 1
  else
    assert_success || return 1
    case $expected in
      debian) assert_output_contains "Debian" || return 1 ;;
      arch) assert_output_contains "Arch" || return 1 ;;
      fedora) assert_output_contains "Fedora" || return 1 ;;
      mac) assert_output_contains "MacOS" || return 1 ;;
      nixos) assert_output_contains "NixOS" || return 1 ;;
    esac
  fi
}

run_test_case "detect-distro shows usage with --help" shows_usage_on_help
run_test_case "detect-distro rejects unexpected arguments" rejects_unexpected_arguments
run_test_case "detect-distro prints the detected identifier" prints_detected_identifier
run_test_case "detect-distro narrates with -v" verbose_mode_narrates

finish_tests
