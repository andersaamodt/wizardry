#!/bin/sh
# Tests for the 'detect-indent-width' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_detect_2space_width() {
  tmpfile="$WIZARDRY_TMPDIR/2space.nix"
  printf '{\n  foo = true;\n  bar = 1;\n}\n' > "$tmpfile"
  run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-width" "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  case "$OUTPUT" in
    2*) return 0 ;;
    *) TEST_FAILURE_REASON="expected '2' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_detect_4space_width() {
  tmpfile="$WIZARDRY_TMPDIR/4space.nix"
  printf '{\n    foo = true;\n    bar = 1;\n}\n' > "$tmpfile"
  run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-width" "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  case "$OUTPUT" in
    4*) return 0 ;;
    *) TEST_FAILURE_REASON="expected '4' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_detect_default_for_missing_file() {
  run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-width" "/nonexistent/file.nix"
  assert_success
  case "$OUTPUT" in
    2*) return 0 ;;
    *) TEST_FAILURE_REASON="expected '2' as default but got '$OUTPUT'"; return 1 ;;
  esac
}

run_test_case "detect-indent-width detects 2-space width" test_detect_2space_width
run_test_case "detect-indent-width detects 4-space width" test_detect_4space_width
run_test_case "detect-indent-width defaults to 2 for missing file" test_detect_default_for_missing_file

finish_tests
