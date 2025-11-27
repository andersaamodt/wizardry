#!/bin/sh
# Behavioral cases (derived from --help):
# - path-wizard prints usage

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/system/path-wizard" --help
  assert_success && assert_error_contains "Usage: path-wizard"
}

test_missing_detect_helper() {
  DETECT_RC_FILE="$WIZARDRY_TMPDIR/missing-detect" run_spell "spells/system/path-wizard" --rc-file "$WIZARDRY_TMPDIR/rc" --format shell add 2>/dev/null
  assert_failure && assert_error_contains "required helper"
}

test_unknown_option() {
  run_spell "spells/system/path-wizard" --unknown
  assert_failure && assert_error_contains "unknown option"
}

test_adds_shell_path_entry() {
  rc="$WIZARDRY_TMPDIR/path_rc"
  detect_stub="$WIZARDRY_TMPDIR/detect-rc-file"
  cat >"$detect_stub" <<'EOF'
#!/bin/sh
printf 'platform=debian\nrc_file=%s\nformat=shell\n' "$WIZARDRY_TMPDIR/path_rc"
EOF
  chmod +x "$detect_stub"

  run_spell "spells/system/path-wizard" --rc-file "$rc" --format shell --platform debian add "$WIZARDRY_TMPDIR"
  assert_success
  assert_file_contains "$rc" "wizardry: path-"
  assert_file_contains "$rc" "export PATH=\"$WIZARDRY_TMPDIR:\$PATH\""
}

test_status_requires_directory() {
  run_spell "spells/system/path-wizard" status
  assert_failure && assert_error_contains "expects a directory argument"
}

test_shell_status_succeeds_when_present() {
  rc="$WIZARDRY_TMPDIR/shell_rc"
  dir="$WIZARDRY_TMPDIR/shell_dir"
  mkdir -p "$dir"

  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --rc-file "$rc" --format shell add "$dir"
  assert_success && assert_file_contains "$rc" "export PATH=\"$dir:\$PATH\""

  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --rc-file "$rc" --format shell status "$dir"
  assert_success
}

test_shell_remove_handles_missing_rc_file() {
  rc="$WIZARDRY_TMPDIR/missing_rc"
  dir="$WIZARDRY_TMPDIR/rc_dir"
  mkdir -p "$dir"

  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --rc-file "$rc" --format shell remove "$dir"
  assert_failure && assert_error_contains "startup file '$rc' does not exist"
}

test_shell_remove_clears_managed_entries() {
  rc="$WIZARDRY_TMPDIR/managed_rc"
  dir="$WIZARDRY_TMPDIR/managed_dir"
  mkdir -p "$dir"

  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --rc-file "$rc" --format shell add "$dir"
  assert_success && assert_file_contains "$rc" "export PATH=\"$dir:\$PATH\""

  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --rc-file "$rc" --format shell remove "$dir"
  assert_success
  if grep -F "$dir" "$rc" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="expected removal of PATH entry for $dir"
    return 1
  fi
}

test_nix_add_status_and_remove_round_trip() {
  rc="$WIZARDRY_TMPDIR/configuration.nix"
  dir="$WIZARDRY_TMPDIR/nix_dir"
  mkdir -p "$dir"

  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --rc-file "$rc" --format nix add "$dir"
  assert_success && assert_file_contains "$rc" "$dir"

  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --rc-file "$rc" --format nix status "$dir"
  assert_success

  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --rc-file "$rc" --format nix remove "$dir"
  assert_success
  if grep -F "$dir" "$rc" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="expected Nix entry for $dir to be removed"
    return 1
  fi
}

test_nix_backup_uses_numeric_suffix() {
  # Test that multiple backups use numeric suffixes (1, 2, 3) not 'x' suffixes
  rc="$WIZARDRY_TMPDIR/backup_test.nix"
  dir1="$WIZARDRY_TMPDIR/backup_dir1"
  dir2="$WIZARDRY_TMPDIR/backup_dir2"
  mkdir -p "$dir1" "$dir2"

  # Create initial config
  printf '{ }\n' > "$rc"

  # Add first directory - this creates a backup
  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --rc-file "$rc" --format nix add "$dir1"
  assert_success || return 1

  # Count backup files that have 'x' suffix pattern (the old broken behavior)
  x_backups=$(ls "$WIZARDRY_TMPDIR"/backup_test.nix.wizardry.*x* 2>/dev/null | wc -l || printf '0')
  if [ "$x_backups" -gt 0 ]; then
    TEST_FAILURE_REASON="backup files should not have 'x' suffixes, found: $(ls "$WIZARDRY_TMPDIR"/backup_test.nix.wizardry.* 2>/dev/null)"
    return 1
  fi
}

test_nix_recursive_creates_single_backup() {
  # Test that recursive mode creates only one backup, not one per subdirectory
  # This was the bug reported in the issue where NixOS config would get
  # backed up ~20 times (once per subdirectory) causing permission denied errors
  rc="$WIZARDRY_TMPDIR/recursive_backup.nix"
  base_dir="$WIZARDRY_TMPDIR/recursive_dir"
  mkdir -p "$base_dir/sub1" "$base_dir/sub2" "$base_dir/sub3"

  # Create initial config
  printf '{ }\n' > "$rc"

  # Add with --recursive flag - should create only ONE backup
  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --recursive --rc-file "$rc" --format nix add "$base_dir"
  assert_success || return 1

  # Count backup files - should be exactly 1
  backup_count=$(find "$WIZARDRY_TMPDIR" -maxdepth 1 -name 'recursive_backup.nix.wizardry.*' 2>/dev/null | wc -l)
  if [ "$backup_count" -ne 1 ]; then
    TEST_FAILURE_REASON="expected exactly 1 backup file, found $backup_count: $(find "$WIZARDRY_TMPDIR" -maxdepth 1 -name 'recursive_backup.nix.wizardry.*' 2>/dev/null | tr '\n' ' ')"
    return 1
  fi
}

test_dry_run_single_directory() {
  dir="$WIZARDRY_TMPDIR/dryrun_dir"
  mkdir -p "$dir"
  
  run_spell "spells/system/path-wizard" --dry-run add "$dir"
  assert_success
  # Dry run should output the directory path
  case "$OUTPUT" in
    *"$dir"*) : ;;
    *) TEST_FAILURE_REASON="expected directory path in output: $dir"; return 1 ;;
  esac
}

test_dry_run_recursive() {
  base="$WIZARDRY_TMPDIR/dryrun_recursive"
  mkdir -p "$base/sub1" "$base/sub2"
  
  run_spell "spells/system/path-wizard" --dry-run --recursive add "$base"
  assert_success
  # Dry run should output all directories
  case "$OUTPUT" in
    *"$base"*) : ;;
    *) TEST_FAILURE_REASON="expected base directory in output"; return 1 ;;
  esac
  case "$OUTPUT" in
    *"sub1"*) : ;;
    *) TEST_FAILURE_REASON="expected sub1 in output"; return 1 ;;
  esac
  case "$OUTPUT" in
    *"sub2"*) : ;;
    *) TEST_FAILURE_REASON="expected sub2 in output"; return 1 ;;
  esac
}

test_dry_run_does_not_modify_rc() {
  rc="$WIZARDRY_TMPDIR/dryrun_rc"
  dir="$WIZARDRY_TMPDIR/dryrun_nomod"
  mkdir -p "$dir"
  
  # Create empty rc file
  printf '' > "$rc"
  
  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --dry-run --rc-file "$rc" --format shell add "$dir"
  assert_success
  # RC file should remain empty (not modified)
  if [ -s "$rc" ]; then
    TEST_FAILURE_REASON="rc file should not be modified in dry-run mode"
    return 1
  fi
}

test_nix_adds_with_inline_marker() {
  # Test that path-wizard adds PATH with inline # wizardry marker
  # and doesn't interfere with user's existing PATH definition
  rc="$WIZARDRY_TMPDIR/existing_path.nix"
  dir="$WIZARDRY_TMPDIR/nix_modify_dir"
  mkdir -p "$dir"
  
  # Create a nix file with an existing PATH definition
  cat >"$rc" <<'EOF'
{ config, pkgs, ... }:

{
  environment.sessionVariables.PATH = "/usr/local/bin";
}
EOF
  
  PATH_WIZARD_PLATFORM=nixos run_spell "spells/system/path-wizard" --rc-file "$rc" --format nix add "$dir"
  assert_success || return 1
  
  # The file should contain inline wizardry marker
  assert_file_contains "$rc" "# wizardry" || return 1
  assert_file_contains "$rc" "$dir" || return 1
  # User's original PATH definition should be UNCHANGED
  assert_file_contains "$rc" "environment.sessionVariables.PATH = \"/usr/local/bin\"" || return 1
}

test_nix_allows_multiple_paths() {
  # Test that path-wizard can add multiple paths with inline markers
  rc="$WIZARDRY_TMPDIR/wizardry_managed.nix"
  dir1="$WIZARDRY_TMPDIR/managed_dir1"
  dir2="$WIZARDRY_TMPDIR/managed_dir2"
  mkdir -p "$dir1" "$dir2"
  
  # First, add a directory
  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --rc-file "$rc" --format nix add "$dir1"
  assert_success || return 1
  
  # Now add another directory
  PATH_WIZARD_PLATFORM=debian run_spell "spells/system/path-wizard" --rc-file "$rc" --format nix add "$dir2"
  assert_success || return 1
  
  # Both directories should be in the file with markers
  assert_file_contains "$rc" "$dir1" || return 1
  assert_file_contains "$rc" "$dir2" || return 1
  # Each should have its own inline marker
  wizardry_count=$(grep -c "# wizardry" "$rc" 2>/dev/null || printf '0')
  if [ "$wizardry_count" -lt 2 ]; then
    TEST_FAILURE_REASON="expected at least 2 wizardry markers, found $wizardry_count"
    return 1
  fi
}

run_test_case "path-wizard prints usage" test_help
run_test_case "path-wizard fails when detect helper missing" test_missing_detect_helper
run_test_case "path-wizard rejects unknown options" test_unknown_option
run_test_case "path-wizard adds shell PATH entries" test_adds_shell_path_entry
run_test_case "path-wizard status without directory fails" test_status_requires_directory
run_test_case "path-wizard reports existing shell entries" test_shell_status_succeeds_when_present
run_test_case "path-wizard remove reports missing rc file" test_shell_remove_handles_missing_rc_file
run_test_case "path-wizard remove drops managed shell entries" test_shell_remove_clears_managed_entries
run_test_case "path-wizard manages Nix PATH entries" test_nix_add_status_and_remove_round_trip
run_test_case "path-wizard uses numeric backup suffixes" test_nix_backup_uses_numeric_suffix
run_test_case "path-wizard recursive creates single backup" test_nix_recursive_creates_single_backup
run_test_case "path-wizard --dry-run shows single directory" test_dry_run_single_directory
run_test_case "path-wizard --dry-run recursive shows all dirs" test_dry_run_recursive
run_test_case "path-wizard --dry-run does not modify rc file" test_dry_run_does_not_modify_rc
run_test_case "path-wizard nix adds with inline marker" test_nix_adds_with_inline_marker
run_test_case "path-wizard nix allows multiple paths" test_nix_allows_multiple_paths
finish_tests
