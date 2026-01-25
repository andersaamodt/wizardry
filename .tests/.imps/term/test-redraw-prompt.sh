#!/bin/sh
# Test coverage for redraw-prompt imp

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_redraw_prompt_outputs_prompt() {
  run_spell "spells/.imps/term/redraw-prompt"
  assert_success || return 1
  
  # Should output some kind of prompt (at minimum "$ ")
  [ -n "$OUTPUT" ] || return 1
}

test_redraw_prompt_no_args() {
  run_spell "spells/.imps/term/redraw-prompt"
  assert_success || return 1
}

run_test_case "redraw-prompt outputs a prompt" test_redraw_prompt_outputs_prompt
run_test_case "redraw-prompt works with no arguments" test_redraw_prompt_no_args

finish_tests
