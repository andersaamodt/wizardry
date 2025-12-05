#!/bin/sh
# Tests for the 'drop' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_drop_removes_last_lines() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/drop_test.XXXXXX")
  printf 'a\nb\nc\nd\ne\n' > "$tmpfile"
  run_cmd sh -c "cat '$tmpfile' | $ROOT_DIR/spells/.imps/text/drop 2"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "a"
  assert_output_contains "b"
  assert_output_contains "c"
  case "$OUTPUT" in
    *d*|*e*) TEST_FAILURE_REASON="output should not contain d or e"; return 1 ;;
  esac
}

test_drop_handles_empty_input() {
  run_cmd sh -c "printf '' | $ROOT_DIR/spells/.imps/text/drop 1"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "drop removes last N lines" test_drop_removes_last_lines
run_test_case "drop handles empty input" test_drop_handles_empty_input

finish_tests
