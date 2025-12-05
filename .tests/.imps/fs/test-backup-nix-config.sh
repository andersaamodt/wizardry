#!/bin/sh
# Tests for the 'backup-nix-config' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
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


test_backup_nix_config_creates_backup() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  printf '{ }\n' > "$nix_file"
  
  run_spell spells/.imps/fs/backup-nix-config "$nix_file"
  assert_success
  
  # Stderr should contain the backup path with .wizardry. suffix
  case "$ERROR" in
    *".wizardry."*)
      : # Found
      ;;
    *)
      TEST_FAILURE_REASON="stderr should contain backup path with .wizardry. suffix: $ERROR"
      return 1
      ;;
  esac
}

test_backup_nix_config_notifies_user() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  printf '{ }\n' > "$nix_file"
  
  run_spell spells/.imps/fs/backup-nix-config "$nix_file"
  assert_success
  
  # Stderr should contain user notification
  assert_error_contains "Backed up"
  assert_error_contains "$nix_file"
}

test_backup_nix_config_missing_file_succeeds() {
  # When file doesn't exist, there's nothing to back up - this should succeed
  run_spell spells/.imps/fs/backup-nix-config "/nonexistent/file.nix"
  assert_success
}

test_backup_nix_config_no_args_fails() {
  run_spell spells/.imps/fs/backup-nix-config
  assert_failure
  assert_error_contains "file path required"
}

test_backup_nix_config_timestamp_suffix() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  printf '{ }\n' > "$nix_file"
  
  run_spell spells/.imps/fs/backup-nix-config "$nix_file"
  assert_success
  
  # Stderr should contain timestamp pattern (YYYYMMDDHHMMSS or epoch seconds)
  case "$ERROR" in
    *".wizardry."[0-9]*)
      : # Valid timestamp
      ;;
    *)
      TEST_FAILURE_REASON="backup should have numeric timestamp suffix: $ERROR"
      return 1
      ;;
  esac
}

test_backup_nix_config_preserves_content() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  original_content='{ pkgs, ... }: { programs.bash.enable = true; }'
  printf '%s\n' "$original_content" > "$nix_file"
  
  # Run directly and capture stderr to find backup path
  stderr=$("$ROOT_DIR/spells/.imps/fs/backup-nix-config" "$nix_file" 2>&1)
  
  # Extract backup path from stderr message
  backup_path=$(printf '%s' "$stderr" | sed -n "s/.*to '\([^']*\)'.*/\1/p")
  
  if [ -z "$backup_path" ]; then
    TEST_FAILURE_REASON="could not extract backup path from: $stderr"
    return 1
  fi
  
  if [ ! -f "$backup_path" ]; then
    TEST_FAILURE_REASON="backup file was not created at: $backup_path"
    return 1
  fi
  
  # Check content is preserved
  if ! grep -q "programs.bash.enable" "$backup_path"; then
    TEST_FAILURE_REASON="backup content does not match original"
    return 1
  fi
  
  # Clean up
  rm -f "$backup_path"
}

run_test_case "backup-nix-config creates backup" test_backup_nix_config_creates_backup
run_test_case "backup-nix-config notifies user" test_backup_nix_config_notifies_user
run_test_case "backup-nix-config missing file succeeds" test_backup_nix_config_missing_file_succeeds
run_test_case "backup-nix-config no args fails" test_backup_nix_config_no_args_fails
run_test_case "backup-nix-config uses timestamp suffix" test_backup_nix_config_timestamp_suffix
run_test_case "backup-nix-config preserves content" test_backup_nix_config_preserves_content

finish_tests
