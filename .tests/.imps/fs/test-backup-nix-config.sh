#!/bin/sh
# Tests for the 'backup-nix-config' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

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
