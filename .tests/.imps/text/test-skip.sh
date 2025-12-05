#!/bin/sh
# Tests for the 'skip' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_skip_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/skip_test.XXXXXX")
  printf 'header\ndata1\ndata2\n' > "$tmpfile"
  run_spell spells/.imps/text/skip 1 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "data1"
  case "$OUTPUT" in
    *header*) TEST_FAILURE_REASON="output should not contain header"; return 1 ;;
  esac
}

test_skip_handles_empty_input() {
  run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/text/skip' 1"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "skip from file" test_skip_from_file
run_test_case "skip handles empty input" test_skip_handles_empty_input

finish_tests
