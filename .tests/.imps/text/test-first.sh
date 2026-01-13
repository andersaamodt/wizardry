#!/bin/sh
# Tests for the 'first' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_first_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'first\nsecond\n' > "$tmpfile"
  run_spell spells/.imps/text/first "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "first"
}

test_first_handles_empty_input() {
  run_cmd sh -c "printf '' | $ROOT_DIR/spells/.imps/text/first"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "first reads from file" test_first_from_file
run_test_case "first handles empty input" test_first_handles_empty_input

finish_tests
