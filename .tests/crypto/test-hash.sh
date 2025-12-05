#!/bin/sh
# Behavioral cases (derived from --help):
# - hash prints usage
# - hash validates arguments before computing
# - hash rejects directories and extra arguments
# - hash emits the resolved path and checksum

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
  run_spell "spells/crypto/hash" --help
  assert_success || return 1
  assert_output_contains "Usage: hash" || return 1
  assert_output_contains "Compute the CRC-32 hash" || return 1
}

hash_requires_single_argument() {
  run_spell "spells/crypto/hash"
  assert_failure || return 1
  assert_output_contains "Usage: hash" || return 1
}

hash_fails_on_missing_file() {
  run_spell "spells/crypto/hash" "missing.txt"
  assert_failure || return 1
  assert_output_contains "Your spell fizzles. There is no file." || return 1
}

hash_rejects_directory() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/dir"

  run_spell "spells/crypto/hash" "$tmpdir"
  assert_failure || return 1
  assert_output_contains "Your spell fizzles. There is no file." || return 1
}

hash_rejects_extra_arguments() {
  file="$WIZARDRY_TMPDIR/hash_extra.txt"
  printf 'extra' >"$file"

  run_spell "spells/crypto/hash" "$file" another
  assert_failure || return 1
  assert_output_contains "Usage: hash" || return 1
}

hash_reports_path_and_checksum() {
  tmpdir=$(make_tempdir)
  cp "spells/crypto/hash" "$tmpdir/hash"
  sample_path="$tmpdir/sample.txt"
  printf 'hash me' >"$sample_path"
  checksum=$(cksum "$sample_path" | awk '{print $1}')

  run_cmd "$tmpdir/hash" "sample.txt"
  assert_success || return 1
  # Normalize path for macOS compatibility (TMPDIR ends with /)
  normalized_path=$(printf '%s' "$sample_path" | sed 's|//|/|g')
  expected_output=$(printf '%s\n0x%x\n' "$normalized_path" "$checksum")
  [ "$OUTPUT" = "$expected_output" ] || {
    TEST_FAILURE_REASON="hash output did not match expected path and checksum"
    return 1
  }
}

run_test_case "hash prints usage" test_help
run_test_case "hash requires exactly one argument" hash_requires_single_argument
run_test_case "hash fails when the file is missing" hash_fails_on_missing_file
run_test_case "hash fails when given a directory" hash_rejects_directory
run_test_case "hash rejects extra arguments" hash_rejects_extra_arguments
run_test_case "hash reports the resolved path and checksum" hash_reports_path_and_checksum

finish_tests
