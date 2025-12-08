#!/bin/sh
# Tests for the 'backup-nix-config' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_backup_nix_config_creates_backup() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  nix_file="$tmpdir/test.nix"
  printf '{ }\n' > "$nix_file"
  
  _run_spell spells/.imps/fs/backup-nix-config "$nix_file"
  _assert_success
  
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
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  nix_file="$tmpdir/test.nix"
  printf '{ }\n' > "$nix_file"
  
  _run_spell spells/.imps/fs/backup-nix-config "$nix_file"
  _assert_success
  
  # Stderr should contain user notification
  _assert_error_contains "Backed up"
  _assert_error_contains "$nix_file"
}

test_backup_nix_config_missing_file_succeeds() {
  # When file doesn't exist, there's nothing to back up - this should succeed
  _run_spell spells/.imps/fs/backup-nix-config "/nonexistent/file.nix"
  _assert_success
}

test_backup_nix_config_no_args_fails() {
  skip-if-compiled || return $?
  _run_spell spells/.imps/fs/backup-nix-config
  _assert_failure
  _assert_error_contains "file path required"
}

test_backup_nix_config_timestamp_suffix() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  nix_file="$tmpdir/test.nix"
  printf '{ }\n' > "$nix_file"
  
  _run_spell spells/.imps/fs/backup-nix-config "$nix_file"
  _assert_success
  
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
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
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

_run_test_case "backup-nix-config creates backup" test_backup_nix_config_creates_backup
_run_test_case "backup-nix-config notifies user" test_backup_nix_config_notifies_user
_run_test_case "backup-nix-config missing file succeeds" test_backup_nix_config_missing_file_succeeds
_run_test_case "backup-nix-config no args fails" test_backup_nix_config_no_args_fails
_run_test_case "backup-nix-config uses timestamp suffix" test_backup_nix_config_timestamp_suffix
_run_test_case "backup-nix-config preserves content" test_backup_nix_config_preserves_content

_finish_tests
