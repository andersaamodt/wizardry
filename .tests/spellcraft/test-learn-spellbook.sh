#!/bin/sh
# Behavioral cases (derived from --help):
# - learn-spellbook prints usage

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Helper functions for creating test stubs
_stub_detect_rc_file() {
  rc_file_path=$1
  stub_dir=$2
  cat >"$stub_dir/detect-rc-file" <<EOF
#!/bin/sh
printf '%s\\n' '$rc_file_path'
EOF
  chmod +x "$stub_dir/detect-rc-file"
}

_stub_detect_distro() {
  platform=$1
  stub_dir=$2
  cat >"$stub_dir/detect-distro" <<EOF
#!/bin/sh
printf '%s\\n' '$platform'
EOF
  chmod +x "$stub_dir/detect-distro"
}

_stub_require_wizardry() {
  stub_dir=$1
  cat >"$stub_dir/require-wizardry" <<'EOF'
#!/bin/sh
# Stub that always succeeds (wizardry is "installed")
exit 0
EOF
  chmod +x "$stub_dir/require-wizardry"
}

test_help() {
  _run_spell "spells/spellcraft/learn-spellbook" --help
  _assert_success && _assert_error_contains "Usage: learn-spellbook"
}

test_missing_detect_helper() {
  # When detect_rc_file is explicitly set to a missing file, learn-spellbook should fail
  # Note: We create a stub detect-rc-file that doesn't exist to test this path
  stub_dir="$WIZARDRY_TMPDIR/detect-stub-dir"
  mkdir -p "$stub_dir"
  # Create a wrapper script that sets detect_rc_file and runs learn-spellbook
  cat >"$stub_dir/test-script" <<'SCRIPT'
#!/bin/sh
export detect_rc_file="$1"
shift
exec "$@"
SCRIPT
  chmod +x "$stub_dir/test-script"
  
  _run_cmd "$stub_dir/test-script" "$WIZARDRY_TMPDIR/missing-detect" \
    "$ROOT_DIR/spells/spellcraft/learn-spellbook" --rc-file "$WIZARDRY_TMPDIR/rc" --format shell add
  _assert_failure && _assert_error_contains "required helper"
}

test_unknown_option() {
  _run_spell "spells/spellcraft/learn-spellbook" --unknown
  _assert_failure && _assert_error_contains "unknown option"
}

test_adds_shell_path_entry() {
  rc="$WIZARDRY_TMPDIR/path_rc"
  stub_bin="$WIZARDRY_TMPDIR/bin"
  mkdir -p "$stub_bin"
  
  # Create stubs using helper functions
  _stub_detect_rc_file "$rc" "$stub_bin"
  _stub_detect_distro "debian" "$stub_bin"

  # Use _run_cmd with PATH set to include stubs
  _run_cmd PATH="$stub_bin:$PATH" "$ROOT_DIR/spells/spellcraft/learn-spellbook" add "$WIZARDRY_TMPDIR"
  _assert_success
  _assert_file_contains "$rc" "wizardry: path-"
  _assert_file_contains "$rc" "export PATH=\"$WIZARDRY_TMPDIR:\$PATH\""
}

test_status_requires_directory() {
  _run_spell "spells/spellcraft/learn-spellbook" status
  _assert_failure && _assert_error_contains "expects a directory argument"
}

test_shell_status_succeeds_when_present() {
  rc="$WIZARDRY_TMPDIR/shell_rc"
  dir="$WIZARDRY_TMPDIR/shell_dir"
  mkdir -p "$dir"
  
  stub_bin="$WIZARDRY_TMPDIR/bin_status"
  mkdir -p "$stub_bin"
  
  # Create stubs using helper functions
  _stub_detect_rc_file "$rc" "$stub_bin"
  _stub_detect_distro "debian" "$stub_bin"
  _stub_require_wizardry "$stub_bin"

  # Use detect_rc_file env var to force the RC file location outside sandbox
  PATH="$stub_bin:$PATH" detect_rc_file="$stub_bin/detect-rc-file" _run_spell "spells/spellcraft/learn-spellbook" add "$dir"
  _assert_success || return 1
  _assert_file_contains "$rc" "export PATH=\"$dir:\$PATH\"" || return 1

  PATH="$stub_bin:$PATH" detect_rc_file="$stub_bin/detect-rc-file" _run_spell "spells/spellcraft/learn-spellbook" status "$dir"
  _assert_success
}

test_shell_remove_handles_missing_rc_file() {
  rc="$WIZARDRY_TMPDIR/missing_rc"
  dir="$WIZARDRY_TMPDIR/rc_dir"
  mkdir -p "$dir"
  
  detect_stub="$WIZARDRY_TMPDIR/detect-rc-file-missing"
  cat >"$detect_stub" <<EOF
#!/bin/sh
printf '%s\n' '$rc'
EOF
  chmod +x "$detect_stub"

  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" remove "$dir"
  _assert_failure && _assert_error_contains "startup file '$rc' does not exist"
}

test_shell_remove_clears_managed_entries() {
  rc="$WIZARDRY_TMPDIR/managed_rc"
  dir="$WIZARDRY_TMPDIR/managed_dir"
  mkdir -p "$dir"
  
  detect_stub="$WIZARDRY_TMPDIR/detect-rc-file-managed"
  cat >"$detect_stub" <<EOF
#!/bin/sh
printf '%s\n' '$rc'
EOF
  chmod +x "$detect_stub"

  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" add "$dir"
  _assert_success && _assert_file_contains "$rc" "export PATH=\"$dir:\$PATH\""

  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" remove "$dir"
  _assert_success
  if grep -F "$dir" "$rc" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="expected removal of PATH entry for $dir"
    return 1
  fi
}

test_nix_add_status_and_remove_round_trip() {
  rc="$WIZARDRY_TMPDIR/configuration.nix"
  dir="$WIZARDRY_TMPDIR/nix_dir"
  mkdir -p "$dir"
  
  detect_stub="$WIZARDRY_TMPDIR/detect-rc-file-nix"
  cat >"$detect_stub" <<EOF
#!/bin/sh
printf '%s\n' '$rc'
EOF
  chmod +x "$detect_stub"

  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" add "$dir"
  _assert_success && _assert_file_contains "$rc" "$dir"

  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" status "$dir"
  _assert_success

  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" remove "$dir"
  _assert_success
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
  
  detect_stub="$WIZARDRY_TMPDIR/detect-rc-file-backup"
  cat >"$detect_stub" <<EOF
#!/bin/sh
printf '%s\n' '$rc'
EOF
  chmod +x "$detect_stub"

  # Add first directory - this creates a backup
  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" add "$dir1"
  _assert_success || return 1

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
  
  stub_bin="$WIZARDRY_TMPDIR/bin_recursive"
  mkdir -p "$stub_bin"
  
  # Create stubs using helper functions
  _stub_detect_rc_file "$rc" "$stub_bin"
  _stub_detect_distro "nixos" "$stub_bin"
  _stub_require_wizardry "$stub_bin"

  # Add with --recursive flag - should create only ONE backup
  # Use _run_cmd to ensure all imps are available in PATH
  PATH="$stub_bin:$PATH" _run_cmd "spells/spellcraft/learn-spellbook" --recursive add "$base_dir"
  _assert_success || return 1

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
  
  _run_spell "spells/spellcraft/learn-spellbook" --dry-run add "$dir"
  _assert_success
  # Dry run should output the directory path
  case "$OUTPUT" in
    *"$dir"*) : ;;
    *) TEST_FAILURE_REASON="expected directory path in output: $dir"; return 1 ;;
  esac
}

test_dry_run_recursive() {
  base="$WIZARDRY_TMPDIR/dryrun_recursive"
  mkdir -p "$base/sub1" "$base/sub2"
  
  _run_spell "spells/spellcraft/learn-spellbook" --dry-run --recursive add "$base"
  _assert_success
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
  
  detect_stub="$WIZARDRY_TMPDIR/detect-rc-file-dryrun"
  cat >"$detect_stub" <<EOF
#!/bin/sh
printf '%s\n' '$rc'
EOF
  chmod +x "$detect_stub"
  
  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" --dry-run add "$dir"
  _assert_success
  # RC file should remain empty (not modified)
  if [ -s "$rc" ]; then
    TEST_FAILURE_REASON="rc file should not be modified in dry-run mode"
    return 1
  fi
}

test_nix_adds_with_inline_marker() {
  # Test that learn-spellbook adds PATH with inline # wizardry marker
  # using environment.sessionVariables.PATH as a multi-line array
  rc="$WIZARDRY_TMPDIR/existing_path.nix"
  dir="$WIZARDRY_TMPDIR/nix_modify_dir"
  mkdir -p "$dir"
  
  # Create a nix file with basic structure
  cat >"$rc" <<'EOF'
{ config, pkgs, ... }:

{
  programs.bash.enable = true;
}
EOF
  
  detect_stub="$WIZARDRY_TMPDIR/detect-rc-file-nixmarker"
  cat >"$detect_stub" <<EOF
#!/bin/sh
printf '%s\n' '$rc'
EOF
  chmod +x "$detect_stub"
  
  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" add "$dir"
  _assert_success || return 1
  
  # The file should contain inline wizardry marker
  _assert_file_contains "$rc" "# wizardry" || return 1
  _assert_file_contains "$rc" "$dir" || return 1
  # Should use environment.sessionVariables.PATH array format
  _assert_file_contains "$rc" "environment.sessionVariables.PATH = [" || return 1
  # User's original content should be preserved
  _assert_file_contains "$rc" "programs.bash.enable = true" || return 1
}

test_nix_allows_multiple_paths() {
  # Test that learn-spellbook can add multiple paths
  # With the new format, all paths are in environment.sessionVariables.PATH array
  rc="$WIZARDRY_TMPDIR/wizardry_managed.nix"
  dir1="$WIZARDRY_TMPDIR/managed_dir1"
  dir2="$WIZARDRY_TMPDIR/managed_dir2"
  mkdir -p "$dir1" "$dir2"
  
  detect_stub="$WIZARDRY_TMPDIR/detect-rc-file-multipaths"
  cat >"$detect_stub" <<EOF
#!/bin/sh
printf '%s\n' '$rc'
EOF
  chmod +x "$detect_stub"
  
  # First, add a directory
  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" add "$dir1"
  _assert_success || return 1
  
  # Now add another directory
  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" add "$dir2"
  _assert_success || return 1
  
  # Both directories should be in the file
  _assert_file_contains "$rc" "$dir1" || return 1
  _assert_file_contains "$rc" "$dir2" || return 1
  # Each path should have a # wizardry comment
  # Count the number of "# wizardry" markers - should be 2 (one for each path)
  wizardry_count=$(grep -c "# wizardry" "$rc" 2>/dev/null || printf '0')
  if [ "$wizardry_count" -ne 2 ]; then
    TEST_FAILURE_REASON="expected exactly 2 wizardry markers (one per path), found $wizardry_count"
    return 1
  fi
}

test_nix_respects_4space_indentation() {
  skip-if-compiled || return $?
  # Test that learn-spellbook respects 4-space indentation in configuration.nix
  rc="$WIZARDRY_TMPDIR/4space.nix"
  dir="$WIZARDRY_TMPDIR/4space_dir"
  mkdir -p "$dir"
  
  # Create a nix file with 4-space indentation
  cat >"$rc" <<'EOF'
{ config, pkgs, ... }:

{
    programs.bash.enable = true;
    
    environment.systemPackages = with pkgs; [
        vim
    ];
}
EOF
  
  detect_stub="$WIZARDRY_TMPDIR/detect-rc-file-4space"
  cat >"$detect_stub" <<EOF
#!/bin/sh
printf '%s\n' '$rc'
EOF
  chmod +x "$detect_stub"
  
  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" add "$dir"
  _assert_success || return 1
  
  # The file should use 4-space indentation for the PATH block
  # Check that the environment.sessionVariables.PATH line starts with 4 spaces
  if ! grep -q '^    environment.sessionVariables.PATH' "$rc"; then
    TEST_FAILURE_REASON="expected 4-space indentation for environment.sessionVariables.PATH"
    return 1
  fi
  # Check that the path entry has 8-space indentation (level 2)
  if ! grep -q '^        "' "$rc"; then
    TEST_FAILURE_REASON="expected 8-space indentation for path entries"
    return 1
  fi
}

test_nix_respects_tab_indentation() {
  skip-if-compiled || return $?
  # Test that learn-spellbook respects tab indentation in configuration.nix
  rc="$WIZARDRY_TMPDIR/tabs.nix"
  dir="$WIZARDRY_TMPDIR/tab_dir"
  mkdir -p "$dir"
  
  # Create a nix file with tab indentation using printf to ensure real tabs
  printf '{ config, pkgs, ... }:\n\n{\n\tprograms.bash.enable = true;\n}\n' >"$rc"
  
  detect_stub="$WIZARDRY_TMPDIR/detect-rc-file-tabs"
  cat >"$detect_stub" <<EOF
#!/bin/sh
printf '%s\n' '$rc'
EOF
  chmod +x "$detect_stub"
  
  detect_rc_file="$detect_stub" _run_spell "spells/spellcraft/learn-spellbook" add "$dir"
  _assert_success || return 1
  
  # The file should use tab indentation for the PATH block
  # Check that the environment.sessionVariables.PATH line starts with a tab
  if ! grep -q '	environment.sessionVariables.PATH' "$rc"; then
    TEST_FAILURE_REASON="expected tab indentation for environment.sessionVariables.PATH"
    return 1
  fi
  # Check that the path entry has 2-tab indentation (level 2)
  if ! grep -q '		"' "$rc"; then
    TEST_FAILURE_REASON="expected 2-tab indentation for path entries"
    return 1
  fi
}

_run_test_case "learn-spellbook prints usage" test_help
_run_test_case "learn-spellbook fails when detect helper missing" test_missing_detect_helper
_run_test_case "learn-spellbook rejects unknown options" test_unknown_option
_run_test_case "learn-spellbook adds shell PATH entries" test_adds_shell_path_entry
_run_test_case "learn-spellbook status without directory fails" test_status_requires_directory
_run_test_case "learn-spellbook reports existing shell entries" test_shell_status_succeeds_when_present
_run_test_case "learn-spellbook remove reports missing rc file" test_shell_remove_handles_missing_rc_file
_run_test_case "learn-spellbook remove drops managed shell entries" test_shell_remove_clears_managed_entries
_run_test_case "learn-spellbook manages Nix PATH entries" test_nix_add_status_and_remove_round_trip
_run_test_case "learn-spellbook uses numeric backup suffixes" test_nix_backup_uses_numeric_suffix
_run_test_case "learn-spellbook recursive creates single backup" test_nix_recursive_creates_single_backup
_run_test_case "learn-spellbook --dry-run shows single directory" test_dry_run_single_directory
_run_test_case "learn-spellbook --dry-run recursive shows all dirs" test_dry_run_recursive
_run_test_case "learn-spellbook --dry-run does not modify rc file" test_dry_run_does_not_modify_rc
_run_test_case "learn-spellbook nix adds with inline marker" test_nix_adds_with_inline_marker
_run_test_case "learn-spellbook nix allows multiple paths" test_nix_allows_multiple_paths
_run_test_case "learn-spellbook nix respects 4-space indentation" test_nix_respects_4space_indentation
_run_test_case "learn-spellbook nix respects tab indentation" test_nix_respects_tab_indentation
_finish_tests
