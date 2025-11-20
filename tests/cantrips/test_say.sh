#!/bin/sh
# Behavioral cases (derived from --help):
# - say prints messages with newline
# - say expands escapes

set -eu

. "$(dirname "$0")/lib/test_common.sh"

say_prints_with_trailing_newline() {
  run_spell "spells/cantrips/say" "hello world"
  assert_success || return 1
  [ "$OUTPUT" = "hello world" ] || { TEST_FAILURE_REASON="unexpected say output"; return 1; }
}

say_inline_omits_newline() {
  run_cmd "$ROOT_DIR/spells/cantrips/say" "line\\nwith\\nescapes"
  assert_success || return 1
  expected='line
with
escapes'
  [ "$OUTPUT" = "$expected" ] || { TEST_FAILURE_REASON="expected escapes to be interpreted"; return 1; }
}

run_test_case "say prints messages with newline" say_prints_with_trailing_newline
run_test_case "say expands escapes" say_inline_omits_newline

finish_tests
