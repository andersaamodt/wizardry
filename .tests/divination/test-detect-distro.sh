#!/bin/sh
# Behavioral cases (derived from --help):
# - detect-distro shows usage with --help
# - detect-distro rejects unexpected arguments
# - detect-distro prints the detected identifier
# - detect-distro narrates with -v

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
