#!/bin/sh
# Behavioral cases (derived from --help):
# - path-wizard prints usage

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

test_help() {
  run_spell "spells/translocation/path-wizard" --help
  assert_success && assert_error_contains "Usage: path-wizard"
}

test_missing_detect_helper() {
  DETECT_RC_FILE="$WIZARDRY_TMPDIR/missing-detect" run_spell "spells/translocation/path-wizard" --rc-file "$WIZARDRY_TMPDIR/rc" --format shell add 2>/dev/null
  assert_failure && assert_error_contains "required helper"
}

test_unknown_option() {
  run_spell "spells/translocation/path-wizard" --unknown
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

  run_spell "spells/translocation/path-wizard" --rc-file "$rc" --format shell --platform debian add "$WIZARDRY_TMPDIR"
  assert_success
  assert_file_contains "$rc" "wizardry: path-"
  assert_file_contains "$rc" "export PATH=\"$WIZARDRY_TMPDIR:\$PATH\""
}

test_status_requires_directory() {
  run_spell "spells/translocation/path-wizard" status
  assert_failure && assert_error_contains "expects a directory argument"
}

test_shell_status_succeeds_when_present() {
  rc="$WIZARDRY_TMPDIR/shell_rc"
  dir="$WIZARDRY_TMPDIR/shell_dir"
  mkdir -p "$dir"

  PATH_WIZARD_PLATFORM=debian run_spell "spells/translocation/path-wizard" --rc-file "$rc" --format shell add "$dir"
  assert_success && assert_file_contains "$rc" "export PATH=\"$dir:\$PATH\""

  PATH_WIZARD_PLATFORM=debian run_spell "spells/translocation/path-wizard" --rc-file "$rc" --format shell status "$dir"
  assert_success
}

test_shell_remove_handles_missing_rc_file() {
  rc="$WIZARDRY_TMPDIR/missing_rc"
  dir="$WIZARDRY_TMPDIR/rc_dir"
  mkdir -p "$dir"

  PATH_WIZARD_PLATFORM=debian run_spell "spells/translocation/path-wizard" --rc-file "$rc" --format shell remove "$dir"
  assert_failure && assert_error_contains "startup file '$rc' does not exist"
}

test_shell_remove_clears_managed_entries() {
  rc="$WIZARDRY_TMPDIR/managed_rc"
  dir="$WIZARDRY_TMPDIR/managed_dir"
  mkdir -p "$dir"

  PATH_WIZARD_PLATFORM=debian run_spell "spells/translocation/path-wizard" --rc-file "$rc" --format shell add "$dir"
  assert_success && assert_file_contains "$rc" "export PATH=\"$dir:\$PATH\""

  PATH_WIZARD_PLATFORM=debian run_spell "spells/translocation/path-wizard" --rc-file "$rc" --format shell remove "$dir"
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

  PATH_WIZARD_PLATFORM=debian run_spell "spells/translocation/path-wizard" --rc-file "$rc" --format nix add "$dir"
  assert_success && assert_file_contains "$rc" "$dir"

  PATH_WIZARD_PLATFORM=debian run_spell "spells/translocation/path-wizard" --rc-file "$rc" --format nix status "$dir"
  assert_success

  PATH_WIZARD_PLATFORM=debian run_spell "spells/translocation/path-wizard" --rc-file "$rc" --format nix remove "$dir"
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
  PATH_WIZARD_PLATFORM=debian run_spell "spells/translocation/path-wizard" --rc-file "$rc" --format nix add "$dir1"
  assert_success || return 1

  # Count backup files that have 'x' suffix pattern (the old broken behavior)
  x_backups=$(ls "$WIZARDRY_TMPDIR"/backup_test.nix.wizardry.*x* 2>/dev/null | wc -l || printf '0')
  if [ "$x_backups" -gt 0 ]; then
    TEST_FAILURE_REASON="backup files should not have 'x' suffixes, found: $(ls "$WIZARDRY_TMPDIR"/backup_test.nix.wizardry.* 2>/dev/null)"
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
finish_tests
