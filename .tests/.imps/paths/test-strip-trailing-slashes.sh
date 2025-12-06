#!/bin/sh
# Tests for the 'strip-trailing-slashes' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_strip_trailing_slashes_removes_slash() {
  _run_spell spells/.imps/paths/strip-trailing-slashes "/tmp/foo/"
  _assert_success
  _assert_output_contains "/tmp/foo"
  # Should not end with a slash
  case "$OUTPUT" in
    */) TEST_FAILURE_REASON="should strip trailing slash"; return 1 ;;
    *) return 0 ;;
  esac
}

test_strip_trailing_slashes_root() {
  _run_spell spells/.imps/paths/strip-trailing-slashes "/"
  _assert_success
  # Root should remain as /
  case "$OUTPUT" in
    /) return 0 ;;
    *) TEST_FAILURE_REASON="root should output /, got: $OUTPUT"; return 1 ;;
  esac
}

test_strip_trailing_slashes_multiple() {
  _run_spell spells/.imps/paths/strip-trailing-slashes "///"
  _assert_success
  # Multiple slashes should become /
  case "$OUTPUT" in
    /) return 0 ;;
    *) TEST_FAILURE_REASON="multiple slashes should output /, got: $OUTPUT"; return 1 ;;
  esac
}

test_strip_trailing_slashes_no_change() {
  _run_spell spells/.imps/paths/strip-trailing-slashes "/tmp/foo"
  _assert_success
  _assert_output_contains "/tmp/foo"
}

_run_test_case "strip-trailing-slashes removes trailing slash" test_strip_trailing_slashes_removes_slash
_run_test_case "strip-trailing-slashes handles root" test_strip_trailing_slashes_root
_run_test_case "strip-trailing-slashes handles multiple slashes" test_strip_trailing_slashes_multiple
_run_test_case "strip-trailing-slashes handles no trailing slash" test_strip_trailing_slashes_no_change

_finish_tests
