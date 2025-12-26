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
  _run_spell "spells/arcane/file-list" --help
  _assert_success || return 1
  _assert_output_contains "Usage: file-list" || return 1
}

test_requires_argument() {
  _run_spell "spells/arcane/file-list"
  _assert_failure || return 1
  _assert_error_contains "Usage: file-list" || return 1
}

test_creates_file() {
  tmpdir=$(_make_tempdir)
  mkdir -p "$tmpdir/testfolder"
  touch "$tmpdir/testfolder/file1.txt"
  touch "$tmpdir/testfolder/file2.txt"
  cd "$tmpdir"
  _run_spell "spells/arcane/file-list" "testfolder"
  _assert_success || return 1
  [ -f "testfolder.txt" ] || { TEST_FAILURE_REASON="output file not created"; return 1; }
}

_run_test_case "file-list shows usage text" test_help
_run_test_case "file-list requires folder argument" test_requires_argument
_run_test_case "file-list creates output file" test_creates_file


# Test via source-then-invoke pattern  
file_list_help_via_sourcing() {
  _run_sourced_spell file-list --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "file-list works via source-then-invoke" file_list_help_via_sourcing
_finish_tests
