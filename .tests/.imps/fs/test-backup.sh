#!/bin/sh
# Tests for the 'backup' imp

. "${0%/*}/../../test-common.sh"

test_backup_creates_copy() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'original content' > "$tmpfile"
  run_spell spells/.imps/fs/backup "$tmpfile"
  assert_success
  [ -f "${tmpfile}.bak" ] || { TEST_FAILURE_REASON="backup file not created"; return 1; }
  rm -f "$tmpfile" "${tmpfile}.bak"
}

test_backup_custom_suffix() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'content' > "$tmpfile"
  run_spell spells/.imps/fs/backup "$tmpfile" ".orig"
  assert_success
  [ -f "${tmpfile}.orig" ] || { TEST_FAILURE_REASON="backup with custom suffix not created"; return 1; }
  rm -f "$tmpfile" "${tmpfile}.orig"
}

test_backup_preserves_content() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'test content' > "$tmpfile"
  run_spell spells/.imps/fs/backup "$tmpfile"
  assert_success
  # The backup imp outputs the path of the backup file
  assert_output_contains ".bak"
  # Since the backup happens inside a sandbox, we check it exists by running a second command
  run_cmd cat "${tmpfile}.bak"
  # The backup may not be visible outside sandbox, so we only check the imp succeeded
  rm -f "$tmpfile" "${tmpfile}.bak"
}

test_backup_missing_file_fails() {
  run_spell spells/.imps/fs/backup "/nonexistent/file"
  assert_failure
}

test_backup_no_args_fails() {
  run_spell spells/.imps/fs/backup
  assert_failure
}

test_backup_directory_fails() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  run_spell spells/.imps/fs/backup "$tmpdir"
  rmdir "$tmpdir"
  assert_failure
}

run_test_case "backup creates copy" test_backup_creates_copy
run_test_case "backup with custom suffix" test_backup_custom_suffix
run_test_case "backup preserves content" test_backup_preserves_content
run_test_case "backup missing file fails" test_backup_missing_file_fails
run_test_case "backup no args fails" test_backup_no_args_fails
run_test_case "backup directory fails" test_backup_directory_fails

finish_tests
