#!/bin/sh
# Test the run-sourced-spell test helper

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_forall_via_sourcing() {
  # Create a test directory with files
  tmpdir=$(_make_tempdir)
  printf 'content1\n' > "$tmpdir/file1.txt"
  printf 'content2\n' > "$tmpdir/file2.txt"
  
  # Run forall via the sourced pattern
  RUN_CMD_WORKDIR=$tmpdir _run_sourced_spell forall cat
  
  # Should succeed
  _assert_success || return 1
  
  # Should list files
  _assert_output_contains "file1.txt" || return 1
  _assert_output_contains "file2.txt" || return 1
  
  # Should show file contents
  _assert_output_contains "content1" || return 1
  _assert_output_contains "content2" || return 1
}

test_menu_help_via_sourcing() {
  # Test that menu --help works when sourced
  # Note: menu outputs usage to stderr, not stdout
  _run_sourced_spell menu --help
  
  _assert_success || return 1
  _assert_error_contains "Usage: menu" || return 1
}

_run_test_case "forall works via source-then-invoke" test_forall_via_sourcing
_run_test_case "menu --help works via source-then-invoke" test_menu_help_via_sourcing

_finish_tests
