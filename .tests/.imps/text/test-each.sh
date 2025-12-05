#!/bin/sh
# Tests for the 'each' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_each_runs_for_lines() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'a\nb\n' > "$tmpfile"
  _run_cmd sh -c "cat '$tmpfile' | '$ROOT_DIR/spells/.imps/text/each' echo 'item:'"
  rm -f "$tmpfile"
  _assert_success
  _assert_output_contains "item: a"
  _assert_output_contains "item: b"
}

test_each_handles_empty_input() {
  _run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/text/each' echo 'item:'"
  _assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

_run_test_case "each runs for each line" test_each_runs_for_lines
_run_test_case "each handles empty input" test_each_handles_empty_input

_finish_tests
