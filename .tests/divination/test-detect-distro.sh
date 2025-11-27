#!/bin/sh
# Behavioral cases (derived from --help):
# - detect-distro shows usage with --help
# - detect-distro rejects unexpected arguments
# - detect-distro prints the detected identifier
# - detect-distro narrates with -v

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

make_fake_root() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/detect-distro.XXXXXX") || return 1
  mkdir -p "$dir/etc"
  printf '%s' "$dir"
}

run_with_root() {
  root=$1
  shift
  DETECT_DISTRO_ROOT="$root" \
  DETECT_DISTRO_OS_RELEASE="$root/etc/os-release" \
  run_spell "spells/divination/detect-distro" "$@"
}

write_os_release() {
  target=$1
  shift
  cat >"$target" <<EOF
$*
EOF
}

shows_usage_on_help() {
  run_spell "spells/divination/detect-distro" "--help"
  assert_success || return 1
  assert_output_contains "Usage: detect-distro" || return 1
}

rejects_unexpected_arguments() {
  run_spell "spells/divination/detect-distro" "extra"
  assert_failure || return 1
  assert_error_contains "Usage: detect-distro" || return 1
}

prints_detected_identifier() {
  root=$(make_fake_root)
  write_os_release "$root/etc/os-release" "ID=debian"
  run_with_root "$root"
  assert_success || return 1
  [ "$OUTPUT" = "debian" ] || { TEST_FAILURE_REASON="expected 'debian' but saw '$OUTPUT'"; return 1; }
  rm -rf "$root"
}

verbose_mode_narrates() {
  root=$(make_fake_root)
  write_os_release "$root/etc/os-release" "ID=fedora"
  run_with_root "$root" "-v"
  assert_success || return 1
  assert_output_contains "Fedora detected" || return 1
  rm -rf "$root"
}

prefers_nixos_markers_even_with_other_signatures() {
  root=$(make_fake_root)
  write_os_release "$root/etc/os-release" "ID=debian"
  : >"$root/etc/NIXOS"
  : >"$root/etc/debian_version"
  run_with_root "$root" "-v"
  assert_success || return 1
  [ "$OUTPUT" = "NixOS detected." ] || { TEST_FAILURE_REASON="expected NixOS verbose message but saw: $OUTPUT"; return 1; }
  rm -rf "$root"
}

detects_arch_release_marker() {
  root=$(make_fake_root)
  : >"$root/etc/arch-release"
  run_with_root "$root" "-v"
  assert_success || return 1
  assert_output_contains "Arch or Manjaro" || return 1
  rm -rf "$root"
}

detects_mac_via_stubbed_uname() {
  root=$(make_fake_root)
  DETECT_DISTRO_UNAME=Darwin run_with_root "$root"
  assert_success || return 1
  [ "$OUTPUT" = "mac" ] || { TEST_FAILURE_REASON="expected mac but saw $OUTPUT"; return 1; }
  rm -rf "$root"
}

fails_when_no_markers_found() {
  root=$(make_fake_root)
  DETECT_DISTRO_UNAME=Linux run_with_root "$root"
  assert_failure || return 1
  assert_output_contains "unknown" || return 1
  rm -rf "$root"
}

run_test_case "detect-distro shows usage with --help" shows_usage_on_help
run_test_case "detect-distro rejects unexpected arguments" rejects_unexpected_arguments
run_test_case "detect-distro prints the detected identifier" prints_detected_identifier
run_test_case "detect-distro narrates with -v" verbose_mode_narrates
run_test_case "detect-distro prefers nixos markers over other signatures" prefers_nixos_markers_even_with_other_signatures
run_test_case "detect-distro detects arch via release marker" detects_arch_release_marker
run_test_case "detect-distro detects mac via uname fallback" detects_mac_via_stubbed_uname
run_test_case "detect-distro fails when no markers are present" fails_when_no_markers_found

finish_tests
