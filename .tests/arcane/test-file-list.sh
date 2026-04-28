#!/bin/sh
# Test coverage for file-list spell:
# - Shows usage with --help
# - Shows error when no folder provided
# - Creates output file

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/arcane/file-list" --help
  assert_success || return 1
  assert_output_contains "Usage: file-list" || return 1
}

test_requires_argument() {
  run_spell "spells/arcane/file-list"
  assert_failure || return 1
  assert_error_contains "Usage: file-list" || return 1
}

test_creates_file() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/testfolder"
  touch "$tmpdir/testfolder/file1.txt"
  touch "$tmpdir/testfolder/file2.txt"
  cd "$tmpdir"
  run_spell "spells/arcane/file-list" "testfolder"
  assert_success || return 1
  [ -f "testfolder.txt" ] || { TEST_FAILURE_REASON="output file not created"; return 1; }
}

test_rejects_missing_folder() {
  tmpdir=$(make_tempdir)
  cd "$tmpdir"
  run_spell "spells/arcane/file-list" "missing"
  assert_failure || return 1
  assert_error_contains "not a directory" || return 1
  [ ! -f "missing.txt" ] || { TEST_FAILURE_REASON="output file should not be created for missing folder"; return 1; }
}

test_rewrites_existing_file() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/testfolder"
  touch "$tmpdir/testfolder/file1.txt"
  touch "$tmpdir/testfolder/file2.txt"
  cd "$tmpdir"
  run_spell "spells/arcane/file-list" "testfolder"
  assert_success || return 1
  run_spell "spells/arcane/file-list" "testfolder"
  assert_success || return 1
  lines=$(wc -l < "testfolder.txt" | tr -d ' ')
  [ "$lines" = "2" ] || { TEST_FAILURE_REASON="expected rewritten listing with 2 lines, got $lines"; return 1; }
}

run_test_case "file-list shows usage text" test_help
run_test_case "file-list requires folder argument" test_requires_argument
run_test_case "file-list creates output file" test_creates_file
run_test_case "file-list rejects missing folder" test_rejects_missing_folder
run_test_case "file-list rewrites existing output" test_rewrites_existing_file


# Test via source-then-invoke pattern  

finish_tests
