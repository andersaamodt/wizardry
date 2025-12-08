#!/bin/sh
# Behavioral cases:
# - list-files recursively lists all files in a directory
# - list-files -x lists only executable files
# - list-files -t f lists only regular files
# - list-files --help shows usage

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/cantrips/list-files" --help
  _assert_success && _assert_output_contains "Usage:"
}

test_lists_files_recursively() {
  workdir=$(_make_tempdir)
  mkdir -p "$workdir/subdir"
  printf 'content1\n' >"$workdir/file1.txt"
  printf 'content2\n' >"$workdir/subdir/file2.txt"
  
  _run_spell "spells/cantrips/list-files" "$workdir"
  _assert_success || return 1
  _assert_output_contains "file1.txt" || return 1
  _assert_output_contains "file2.txt" || return 1
}

test_lists_executable_files_only() {
  workdir=$(_make_tempdir)
  printf 'script\n' >"$workdir/executable.sh"
  chmod +x "$workdir/executable.sh"
  printf 'text\n' >"$workdir/regular.txt"
  
  _run_spell "spells/cantrips/list-files" "$workdir" -x
  _assert_success || return 1
  _assert_output_contains "executable.sh" || return 1
  # Should not contain non-executable
  case "$OUTPUT" in
    *regular.txt*) TEST_FAILURE_REASON="should not list non-executable files"; return 1 ;;
  esac
}

test_lists_regular_files_only() {
  workdir=$(_make_tempdir)
  mkdir -p "$workdir/subdir"
  printf 'file\n' >"$workdir/file.txt"
  
  _run_spell "spells/cantrips/list-files" "$workdir" -t f
  _assert_success || return 1
  _assert_output_contains "file.txt" || return 1
  # Should not contain directories
  case "$OUTPUT" in
    *subdir*) TEST_FAILURE_REASON="should not list directories with -t f"; return 1 ;;
  esac
}

_run_test_case "list-files prints usage" test_help
_run_test_case "list-files lists files recursively" test_lists_files_recursively
_run_test_case "list-files -x lists executable files only" test_lists_executable_files_only
_run_test_case "list-files -t f lists regular files only" test_lists_regular_files_only

_finish_tests
