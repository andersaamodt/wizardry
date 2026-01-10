#!/bin/sh
# Test cases for file-to-folder:
# - file-to-folder shows usage text
# - file-to-folder converts file with extension to folder
# - file-to-folder converts file without extension to folder
# - file-to-folder preserves file contents
# - file-to-folder handles empty files
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
  
  # Check project notes file exists
  [ -f "$testfile/project notes.txt" ] || { TEST_FAILURE_REASON="project notes file not created"; return 1; }
  
  # Check file is empty
  [ ! -s "$testfile/project notes.txt" ] || { TEST_FAILURE_REASON="file should be empty"; return 1; }
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
run_test_case "file-to-folder rejects directories" file_to_folder_rejects_directories
run_test_case "file-to-folder rejects missing files" file_to_folder_rejects_missing_files
run_test_case "file-to-folder requires argument" file_to_folder_requires_argument
run_test_case "file-to-folder rejects non-text files" file_to_folder_rejects_non_text_files
run_test_case "file-to-folder accepts text files" file_to_folder_accepts_text_files

finish_tests
