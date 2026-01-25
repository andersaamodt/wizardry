#!/bin/sh
# Test coverage for clear-line imp

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_clear_line_outputs_ansi() {
  run_spell "spells/.imps/term/clear-line"
  assert_success || return 1
  
  # Should output carriage return and clear sequence
  # \r = carriage return, \033[K = clear to end of line
  # The output should contain these ANSI sequences
  printf '%s' "$OUTPUT" | od -An -tx1 | grep -q "0d" || return 1  # \r
  printf '%s' "$OUTPUT" | od -An -tx1 | grep -q "1b" || return 1  # ESC
}

test_clear_line_no_args() {
  run_spell "spells/.imps/term/clear-line"
  assert_success || return 1
}

run_test_case "clear-line outputs ANSI sequences" test_clear_line_outputs_ansi
run_test_case "clear-line works with no arguments" test_clear_line_no_args

finish_tests
