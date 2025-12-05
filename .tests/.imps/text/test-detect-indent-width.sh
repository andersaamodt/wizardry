#!/bin/sh
# Tests for the 'detect-indent-width' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_detect_2space_width() {
  tmpfile="$WIZARDRY_TMPDIR/2space.nix"
  printf '{\n  foo = true;\n  bar = 1;\n}\n' > "$tmpfile"
  _run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-width" "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  case "$OUTPUT" in
    2*) return 0 ;;
    *) TEST_FAILURE_REASON="expected '2' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_detect_4space_width() {
  tmpfile="$WIZARDRY_TMPDIR/4space.nix"
  printf '{\n    foo = true;\n    bar = 1;\n}\n' > "$tmpfile"
  _run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-width" "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  case "$OUTPUT" in
    4*) return 0 ;;
    *) TEST_FAILURE_REASON="expected '4' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_detect_default_for_missing_file() {
  _run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-width" "/nonexistent/file.nix"
  _assert_success
  case "$OUTPUT" in
    2*) return 0 ;;
    *) TEST_FAILURE_REASON="expected '2' as default but got '$OUTPUT'"; return 1 ;;
  esac
}

_run_test_case "detect-indent-width detects 2-space width" test_detect_2space_width
_run_test_case "detect-indent-width detects 4-space width" test_detect_4space_width
_run_test_case "detect-indent-width defaults to 2 for missing file" test_detect_default_for_missing_file

_finish_tests
