#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_expand_empty_prompt() {
  _run_spell "spells/.imps/term/expand-prompt" ""
  _assert_success && _assert_output_equals "$ "
}

test_expand_simple_prompt() {
  _run_spell "spells/.imps/term/expand-prompt" "test> "
  _assert_success && _assert_output_equals "test> "
}

test_expand_bash_user() {
  _run_spell "spells/.imps/term/expand-prompt" "\\u@host$ "
  _assert_success && _assert_output_contains "@host$ "
}

test_expand_default_on_empty_result() {
  _run_spell "spells/.imps/term/expand-prompt" ""
  _assert_success && _assert_output_equals "$ "
}

_run_test_case "empty prompt returns default" test_expand_empty_prompt
_run_test_case "simple prompt unchanged" test_expand_simple_prompt
_run_test_case "bash \\u expands to username" test_expand_bash_user
_run_test_case "empty result returns default" test_expand_default_on_empty_result

_finish_tests
