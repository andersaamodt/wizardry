#!/bin/sh
# Tests for the 'take' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_take_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/take_test.XXXXXX")
  printf 'a\nb\nc\nd\ne\n' > "$tmpfile"
  run_spell spells/.imps/text/take 2 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "a"
  assert_output_contains "b"
  case "$OUTPUT" in
    *c*|*d*|*e*) TEST_FAILURE_REASON="output should not contain c, d, or e"; return 1 ;;
  esac
}

test_take_handles_empty_input() {
  run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/text/take' 2"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "take from file" test_take_from_file
run_test_case "take handles empty input" test_take_handles_empty_input

finish_tests
