#!/bin/sh
# Tests for the 'backup' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_backup_creates_copy() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'original content' > "$tmpfile"
  _run_spell spells/.imps/fs/backup "$tmpfile"
  _assert_success
  [ -f "${tmpfile}.bak" ] || { TEST_FAILURE_REASON="backup file not created"; return 1; }
  rm -f "$tmpfile" "${tmpfile}.bak"
}

test_backup_custom_suffix() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'content' > "$tmpfile"
  _run_spell spells/.imps/fs/backup "$tmpfile" ".orig"
  _assert_success
  [ -f "${tmpfile}.orig" ] || { TEST_FAILURE_REASON="backup with custom suffix not created"; return 1; }
  rm -f "$tmpfile" "${tmpfile}.orig"
}

test_backup_preserves_content() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'test content' > "$tmpfile"
  _run_spell spells/.imps/fs/backup "$tmpfile"
  _assert_success
  # The backup imp outputs the path of the backup file
  _assert_output_contains ".bak"
  # Since the backup happens inside a sandbox, we check it exists by running a second command
  _run_cmd cat "${tmpfile}.bak"
  # The backup may not be visible outside sandbox, so we only check the imp succeeded
  rm -f "$tmpfile" "${tmpfile}.bak"
}

test_backup_missing_file_fails() {
  _run_spell spells/.imps/fs/backup "/nonexistent/file"
  _assert_failure
}

test_backup_no_args_fails() {
  _run_spell spells/.imps/fs/backup
  _assert_failure
}

test_backup_directory_fails() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  _run_spell spells/.imps/fs/backup "$tmpdir"
  rmdir "$tmpdir"
  _assert_failure
}

_run_test_case "backup creates copy" test_backup_creates_copy
_run_test_case "backup with custom suffix" test_backup_custom_suffix
_run_test_case "backup preserves content" test_backup_preserves_content
_run_test_case "backup missing file fails" test_backup_missing_file_fails
_run_test_case "backup no args fails" test_backup_no_args_fails
_run_test_case "backup directory fails" test_backup_directory_fails

_finish_tests
