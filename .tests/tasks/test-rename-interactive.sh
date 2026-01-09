#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/tasks/rename-interactive" --help
  assert_success || return 1
  assert_output_contains "Usage: rename-interactive" || return 1
}

test_requires_argument() {
  run_spell "spells/tasks/rename-interactive"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  run_spell "spells/tasks/rename-interactive" "/nonexistent/file.txt"
  assert_failure || return 1
  assert_error_contains "file not found" || return 1
}

test_renames_file() {
  tmpdir=$(make_tempdir)
  oldfile="$tmpdir/oldname.txt"
  newfile="$tmpdir/newname.txt"
  printf 'test content\n' > "$oldfile"
  
  # Provide new name via stdin
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'newname.txt\\n' | \"$ROOT_DIR/spells/tasks/rename-interactive\" \"$oldfile\""
  assert_success || return 1
  assert_output_contains "Renamed" || return 1
  
  # Verify old file is gone and new file exists
  if [ -e "$oldfile" ]; then
    TEST_FAILURE_REASON="Old file still exists"
    return 1
  fi
  
  if [ ! -e "$newfile" ]; then
    TEST_FAILURE_REASON="New file does not exist"
    return 1
  fi
  
  # Verify content is preserved
  content=$(cat "$newfile")
  if [ "$content" != "test content" ]; then
    TEST_FAILURE_REASON="File content changed during rename"
    return 1
  fi
}

test_no_change_when_same_name() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  # Provide same name via stdin (simulating user pressing enter to accept default)
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'test.txt\\n' | \"$ROOT_DIR/spells/tasks/rename-interactive\" \"$testfile\""
  assert_success || return 1
  assert_output_contains "No change" || return 1
  
  # Verify file still exists
  if [ ! -e "$testfile" ]; then
    TEST_FAILURE_REASON="File disappeared even though name didn't change"
    return 1
  fi
}

test_fails_if_target_exists() {
  tmpdir=$(make_tempdir)
  oldfile="$tmpdir/old.txt"
  existing="$tmpdir/existing.txt"
  printf 'old content\n' > "$oldfile"
  printf 'existing content\n' > "$existing"
  
  # Try to rename to existing file
  run_cmd env ASK_CANTRIP_INPUT=stdin sh -c "printf 'existing.txt\\n' | \"$ROOT_DIR/spells/tasks/rename-interactive\" \"$oldfile\""
  assert_failure || return 1
  assert_error_contains "target already exists" || return 1
  
  # Verify both files still exist unchanged
  if [ ! -e "$oldfile" ]; then
    TEST_FAILURE_REASON="Old file was removed despite error"
    return 1
  fi
  if [ ! -e "$existing" ]; then
    TEST_FAILURE_REASON="Existing file was removed"
    return 1
  fi
}

run_test_case "rename-interactive shows usage" test_help
run_test_case "rename-interactive requires file argument" test_requires_argument
run_test_case "rename-interactive fails on missing file" test_fails_on_missing_file
run_test_case "rename-interactive renames file" test_renames_file
run_test_case "rename-interactive handles no change" test_no_change_when_same_name
run_test_case "rename-interactive fails if target exists" test_fails_if_target_exists

finish_tests
