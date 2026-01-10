#!/bin/sh
# Test cases for file-to-folder:
# - file-to-folder shows usage text
# - file-to-folder converts file with extension to folder
# - file-to-folder converts file without extension to folder
# - file-to-folder preserves file contents
# - file-to-folder handles empty files (no project notes created)
# - file-to-folder handles whitespace-only files (no project notes created)
# - file-to-folder rejects directories
# - file-to-folder rejects missing files
# - file-to-folder preserves extended attributes (xattrs)

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

file_to_folder_shows_usage() {
  run_spell "spells/arcane/file-to-folder" --help
  assert_success || return 1
  assert_output_contains "Usage: file-to-folder" || return 1
}

file_to_folder_converts_file_with_extension() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/myfile.txt"
  printf 'test content' > "$testfile"
  
  run_spell "spells/arcane/file-to-folder" "$testfile"
  assert_success || return 1
  assert_output_contains "Converted file to folder" || return 1
  
  # Check folder was created
  [ -d "$testfile" ] || { TEST_FAILURE_REASON="folder not created"; return 1; }
  
  # Check project notes file exists with correct name
  [ -f "$testfile/project notes.txt" ] || { TEST_FAILURE_REASON="project notes file not created"; return 1; }
  
  # Check content was preserved
  content=$(cat "$testfile/project notes.txt")
  [ "$content" = "test content" ] || { TEST_FAILURE_REASON="content not preserved: got '$content'"; return 1; }
}

file_to_folder_converts_file_without_extension() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/README"
  printf 'readme content' > "$testfile"
  
  run_spell "spells/arcane/file-to-folder" "$testfile"
  assert_success || return 1
  
  # Check folder was created
  [ -d "$testfile" ] || { TEST_FAILURE_REASON="folder not created"; return 1; }
  
  # Check project notes file exists without extension
  [ -f "$testfile/project notes" ] || { TEST_FAILURE_REASON="project notes file not created"; return 1; }
  
  # Check content was preserved
  content=$(cat "$testfile/project notes")
  [ "$content" = "readme content" ] || { TEST_FAILURE_REASON="content not preserved"; return 1; }
}

file_to_folder_handles_empty_files() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/empty.txt"
  touch "$testfile"
  
  run_spell "spells/arcane/file-to-folder" "$testfile"
  assert_success || return 1
  
  # Check folder was created
  [ -d "$testfile" ] || { TEST_FAILURE_REASON="folder not created"; return 1; }
  
  # Check project notes file does NOT exist (file was empty)
  [ ! -f "$testfile/project notes.txt" ] || { TEST_FAILURE_REASON="project notes file should not be created for empty file"; return 1; }
}

file_to_folder_handles_whitespace_only_files() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/whitespace.txt"
  printf '   \n\t\n  \n' > "$testfile"
  
  run_spell "spells/arcane/file-to-folder" "$testfile"
  assert_success || return 1
  
  # Check folder was created
  [ -d "$testfile" ] || { TEST_FAILURE_REASON="folder not created"; return 1; }
  
  # Check project notes file does NOT exist (file had only whitespace)
  [ ! -f "$testfile/project notes.txt" ] || { TEST_FAILURE_REASON="project notes file should not be created for whitespace-only file"; return 1; }
}

file_to_folder_rejects_directories() {
  tmpdir=$(make_tempdir)
  testdir="$tmpdir/testdir"
  mkdir -p "$testdir"
  
  run_spell "spells/arcane/file-to-folder" "$testdir"
  assert_failure || return 1
  assert_error_contains "already a folder" || return 1
}

file_to_folder_rejects_missing_files() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/nonexistent.txt"
  
  run_spell "spells/arcane/file-to-folder" "$testfile"
  assert_failure || return 1
  assert_error_contains "does not exist" || return 1
}

file_to_folder_requires_argument() {
  run_spell "spells/arcane/file-to-folder"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

file_to_folder_rejects_non_text_files() {
  tmpdir=$(make_tempdir)
  # Create a binary file (use /dev/zero to ensure it's binary)
  testfile="$tmpdir/binary.dat"
  dd if=/dev/zero of="$testfile" bs=1 count=10 2>/dev/null
  
  run_spell "spells/arcane/file-to-folder" "$testfile"
  assert_failure || return 1
  assert_error_contains "not a plain text file" || return 1
}

file_to_folder_accepts_text_files() {
  tmpdir=$(make_tempdir)
  # Create various text file types
  testfile="$tmpdir/test.txt"
  printf 'plain text content\n' > "$testfile"
  
  run_spell "spells/arcane/file-to-folder" "$testfile"
  assert_success || return 1
  assert_output_contains "Converted file to folder" || return 1
  
  # Check folder was created
  [ -d "$testfile" ] || { TEST_FAILURE_REASON="folder not created"; return 1; }
}

run_test_case "file-to-folder shows usage" file_to_folder_shows_usage
run_test_case "file-to-folder converts file with extension" file_to_folder_converts_file_with_extension
run_test_case "file-to-folder converts file without extension" file_to_folder_converts_file_without_extension
run_test_case "file-to-folder handles empty files" file_to_folder_handles_empty_files
run_test_case "file-to-folder handles whitespace-only files" file_to_folder_handles_whitespace_only_files
run_test_case "file-to-folder rejects directories" file_to_folder_rejects_directories
run_test_case "file-to-folder rejects missing files" file_to_folder_rejects_missing_files
run_test_case "file-to-folder requires argument" file_to_folder_requires_argument
run_test_case "file-to-folder rejects non-text files" file_to_folder_rejects_non_text_files
run_test_case "file-to-folder accepts text files" file_to_folder_accepts_text_files

file_to_folder_transfers_priority_xattr() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test content\n' > "$testfile"
  
  # Try to set priority xattr - if this fails, skip the test
  run_spell "spells/enchant/enchant" "$testfile" "priority=5"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Convert file to folder
  run_spell "spells/arcane/file-to-folder" "$testfile"
  assert_success || return 1
  
  # Check folder was created
  [ -d "$testfile" ] || { TEST_FAILURE_REASON="folder not created"; return 1; }
  
  # Check that priority was transferred to the folder
  run_spell "spells/arcane/read-magic" "$testfile" "priority"
  assert_success || return 1
  assert_output_equals "5" || return 1
  
  # Check that priority was removed from the moved file
  run_spell "spells/arcane/read-magic" "$testfile/project notes.txt" "priority"
  assert_failure || return 1
}

file_to_folder_transfers_echelon_xattr() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test content\n' > "$testfile"
  
  # Try to set priority and echelon xattr - if this fails, skip the test
  run_spell "spells/enchant/enchant" "$testfile" "priority=5"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  run_spell "spells/enchant/enchant" "$testfile" "echelon=2"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Convert file to folder
  run_spell "spells/arcane/file-to-folder" "$testfile"
  assert_success || return 1
  
  # Check folder was created
  [ -d "$testfile" ] || { TEST_FAILURE_REASON="folder not created"; return 1; }
  
  # Check that priority was transferred to the folder
  run_spell "spells/arcane/read-magic" "$testfile" "priority"
  assert_success || return 1
  assert_output_equals "5" || return 1
  
  # Check that echelon was transferred to the folder
  run_spell "spells/arcane/read-magic" "$testfile" "echelon"
  assert_success || return 1
  assert_output_equals "2" || return 1
  
  # Check that priority was removed from the moved file
  run_spell "spells/arcane/read-magic" "$testfile/project notes.txt" "priority"
  assert_failure || return 1
  
  # Check that echelon was removed from the moved file
  run_spell "spells/arcane/read-magic" "$testfile/project notes.txt" "echelon"
  assert_failure || return 1
}

file_to_folder_transfers_echelon_for_empty_file() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/empty.txt"
  touch "$testfile"
  
  # Try to set priority and echelon xattr - if this fails, skip the test
  run_spell "spells/enchant/enchant" "$testfile" "priority=3"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  run_spell "spells/enchant/enchant" "$testfile" "echelon=1"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Convert file to folder
  run_spell "spells/arcane/file-to-folder" "$testfile"
  assert_success || return 1
  
  # Check folder was created
  [ -d "$testfile" ] || { TEST_FAILURE_REASON="folder not created"; return 1; }
  
  # Check that priority was transferred to the folder (even though file was empty)
  run_spell "spells/arcane/read-magic" "$testfile" "priority"
  assert_success || return 1
  assert_output_equals "3" || return 1
  
  # Check that echelon was transferred to the folder (even though file was empty)
  run_spell "spells/arcane/read-magic" "$testfile" "echelon"
  assert_success || return 1
  assert_output_equals "1" || return 1
}

run_test_case "file-to-folder transfers priority xattr to folder" file_to_folder_transfers_priority_xattr
run_test_case "file-to-folder transfers echelon xattr to folder" file_to_folder_transfers_echelon_xattr
run_test_case "file-to-folder transfers echelon for empty file" file_to_folder_transfers_echelon_for_empty_file

finish_tests
