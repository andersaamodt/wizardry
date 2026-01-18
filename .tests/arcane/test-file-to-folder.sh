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
# - file-to-folder transfers priority attribute from file to folder

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

file_to_folder_transfers_priority_attribute() {
  skip-if-compiled || return $?  # Stubs don't work in compiled mode
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  testfile="$tmpdir/myfile.txt"
  mkdir -p "$stub_dir"
  printf 'test content' > "$testfile"
  
  # Create a file to track xattr operations
  operations_log="$tmpdir/xattr_ops.log"
  : > "$operations_log"
  
  # Create stub xattr that simulates priority attribute on file
  cat >"$stub_dir/xattr" <<STUB_SCRIPT
#!/bin/sh
printf 'xattr called: %s\n' "\$*" >> "$operations_log"
case "\$1" in
  -p)
    # Read operation for read-magic
    if [ "\$2" = "user.priority" ]; then
      # Check which file is being read
      case "\$3" in
        *"project notes.txt")
          # After disenchant, priority should not exist on project notes
          exit 1
          ;;
        *)
          # Original file has priority=high
          printf 'high'
          exit 0
          ;;
      esac
    fi
    exit 1
    ;;
  -w)
    # Write operation for enchant
    if [ "\$2" = "user.priority" ] && [ "\$3" = "high" ]; then
      printf 'enchant: priority set to high on %s\n' "\$4" >> "$operations_log"
      exit 0
    fi
    exit 1
    ;;
  -d)
    # Delete operation for disenchant (accepts both priority and user.priority)
    if [ "\$2" = "user.priority" ] || [ "\$2" = "priority" ]; then
      printf 'disenchant: priority removed from %s\n' "\$3" >> "$operations_log"
      exit 0
    fi
    exit 1
    ;;
  *)
    # List operation (no args)
    printf 'user.priority\n'
    exit 0
    ;;
esac
STUB_SCRIPT
  chmod +x "$stub_dir/xattr"
  
  # Run file-to-folder with stub xattr in PATH
  PATH="$stub_dir:$PATH" run_spell "spells/arcane/file-to-folder" "$testfile"
  assert_success || return 1
  
  # Verify folder was created
  [ -d "$testfile" ] || { TEST_FAILURE_REASON="folder not created"; return 1; }
  
  # Verify project notes file exists
  [ -f "$testfile/project notes.txt" ] || { TEST_FAILURE_REASON="project notes file not created"; return 1; }
  
  # Check that disenchant was called to remove priority from the moved file
  if ! grep -q "disenchant: priority removed" "$operations_log"; then
    TEST_FAILURE_REASON="disenchant was not called to remove priority from file"
    return 1
  fi
  
  # Check that enchant was called to set priority on the folder
  if ! grep -q "enchant: priority set to high" "$operations_log"; then
    TEST_FAILURE_REASON="enchant was not called to set priority on folder"
    return 1
  fi
  
  # Verify enchant was called on the folder, not the project notes file
  if ! grep -q "enchant: priority set to high on $testfile\$" "$operations_log"; then
    TEST_FAILURE_REASON="priority was not set on the folder (expected: $testfile)"
    cat "$operations_log" >&2
    return 1
  fi
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
run_test_case "file-to-folder transfers priority attribute" file_to_folder_transfers_priority_attribute

file_to_folder_updates_parent_priorities_list() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test content\n' > "$testfile"
  
  # Try to hash and prioritize the file - if this fails, skip the test
  run_spell "spells/crypto/hashchant" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Get the file's hash
  run_spell "spells/arcane/read-magic" "$testfile" hash
  assert_success || return 1
  file_hash=$OUTPUT
  
  # Prioritize the file (this adds it to the parent's priorities list)
  run_spell "spells/priorities/prioritize" "$testfile"
  assert_success || return 1
  
  # Verify the file's hash is in the parent's priorities list
  run_spell "spells/arcane/read-magic" "$tmpdir" priorities
  assert_success || return 1
  assert_output_contains "$file_hash" || return 1
  
  # Convert file to folder
  run_spell "spells/arcane/file-to-folder" "$testfile"
  assert_success || return 1
  
  # Check folder was created
  [ -d "$testfile" ] || { TEST_FAILURE_REASON="folder not created"; return 1; }
  
  # Get the folder's hash
  run_spell "spells/arcane/read-magic" "$testfile" hash
  assert_success || return 1
  folder_hash=$OUTPUT
  
  # Verify the folder's hash is now in the parent's priorities list
  run_spell "spells/arcane/read-magic" "$tmpdir" priorities
  assert_success || return 1
  assert_output_contains "$folder_hash" || return 1
  
  # Verify the old file hash is NOT in the priorities list
  case "$OUTPUT" in
    *"$file_hash"*) 
      TEST_FAILURE_REASON="old file hash still in priorities list: $OUTPUT"
      return 1
      ;;
  esac
}

run_test_case "file-to-folder updates parent priorities list" file_to_folder_updates_parent_priorities_list

finish_tests
