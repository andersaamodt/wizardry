#!/bin/sh
# Test coverage for file-list spell:
# - Shows error when no folder provided
# - Requires exactly one argument
# - Creates output file

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_requires_argument() {
  run_spell "spells/arcane/file-list"
  assert_failure || return 1
  assert_output_contains "Please provide a folder path" || return 1
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

test_output_contains_files() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/testdir"
  touch "$tmpdir/testdir/sample.txt"
  cd "$tmpdir"
  run_spell "spells/arcane/file-list" "testdir"
  assert_success || return 1
  grep -q "sample.txt" "testdir.txt" || { TEST_FAILURE_REASON="output file missing content"; return 1; }
}

run_test_case "file-list requires folder argument" test_requires_argument
run_test_case "file-list creates output file" test_creates_file
run_test_case "file-list includes files in output" test_output_contains_files

finish_tests
