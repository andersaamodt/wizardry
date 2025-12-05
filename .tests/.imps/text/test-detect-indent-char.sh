#!/bin/sh
# Tests for the 'detect-indent-char' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_detect_space_indent() {
  tmpfile="$WIZARDRY_TMPDIR/space_indent.nix"
  printf '{\n  foo = true;\n  bar = 1;\n}\n' > "$tmpfile"
  _run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-char" "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  case "$OUTPUT" in
    space*) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'space' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_detect_tab_indent() {
  tmpfile="$WIZARDRY_TMPDIR/tab_indent.nix"
  printf '{\n\tfoo = true;\n\tbar = 1;\n}\n' > "$tmpfile"
  _run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-char" "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  case "$OUTPUT" in
    tab*) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'tab' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_detect_default_for_missing_file() {
  _run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-char" "/nonexistent/file.nix"
  _assert_success
  case "$OUTPUT" in
    space*) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'space' as default but got '$OUTPUT'"; return 1 ;;
  esac
}

test_detect_default_for_empty_file() {
  tmpfile="$WIZARDRY_TMPDIR/empty.nix"
  printf '' > "$tmpfile"
  _run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-char" "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  case "$OUTPUT" in
    space*) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'space' as default but got '$OUTPUT'"; return 1 ;;
  esac
}

_run_test_case "detect-indent-char detects space indent" test_detect_space_indent
_run_test_case "detect-indent-char detects tab indent" test_detect_tab_indent
_run_test_case "detect-indent-char defaults to space for missing file" test_detect_default_for_missing_file
_run_test_case "detect-indent-char defaults to space for empty file" test_detect_default_for_empty_file

_finish_tests
