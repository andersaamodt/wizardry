#!/bin/sh
# Tests for the 'abs-path' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_abs_path_directory() {
  tmpdir=$(_make_tempdir)
  mkdir -p "$tmpdir/subdir"
  _run_spell_in_dir "$tmpdir" spells/.imps/paths/abs-path "./subdir"
  _assert_success
  # Should output an absolute path containing subdir
  case "$OUTPUT" in
    *subdir*) return 0 ;;
    *) TEST_FAILURE_REASON="should output absolute path to subdir, got: $OUTPUT"; return 1 ;;
  esac
}

test_abs_path_file() {
  tmpdir=$(_make_tempdir)
  touch "$tmpdir/testfile.txt"
  _run_spell_in_dir "$tmpdir" spells/.imps/paths/abs-path "./testfile.txt"
  _assert_success
  # Should output an absolute path containing the filename
  case "$OUTPUT" in
    */testfile.txt) return 0 ;;
    *) TEST_FAILURE_REASON="should output absolute path to file, got: $OUTPUT"; return 1 ;;
  esac
}

test_abs_path_normalizes_double_slashes() {
  _run_spell spells/.imps/paths/abs-path "/tmp//test"
  _assert_success
  # Should not contain double slashes
  case "$OUTPUT" in
    *//*) TEST_FAILURE_REASON="should normalize double slashes"; return 1 ;;
    *) return 0 ;;
  esac
}

test_abs_path_absolute_input() {
  _run_spell spells/.imps/paths/abs-path "/tmp"
  _assert_success
  _assert_output_contains "/tmp"
}

_run_test_case "abs-path handles directory" test_abs_path_directory
_run_test_case "abs-path handles file" test_abs_path_file
_run_test_case "abs-path normalizes double slashes" test_abs_path_normalizes_double_slashes
_run_test_case "abs-path handles absolute input" test_abs_path_absolute_input

_finish_tests
