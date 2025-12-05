#!/bin/sh
# Test coverage for file-list spell:
# - Shows usage with --help
# - Shows error when no folder provided
# - Creates output file

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_help() {
  run_spell "spells/arcane/file-list" --help
  assert_success || return 1
  assert_output_contains "Usage: file-list" || return 1
}

test_requires_argument() {
  run_spell "spells/arcane/file-list"
  assert_failure || return 1
  assert_output_contains "folder path required" || return 1
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

run_test_case "file-list shows usage text" test_help
run_test_case "file-list requires folder argument" test_requires_argument
run_test_case "file-list creates output file" test_creates_file

finish_tests
