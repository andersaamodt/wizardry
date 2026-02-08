#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/select-llm-to-install" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "select-llm-to-install" || return 1
}

test_requires_menu() {
  skip-if-compiled || return $?
  stub=$(make_tempdir)
  
  # Create PATH without menu command
  link_tools "$stub" sh test
  
  run_cmd sh -c "
    PATH='$stub:/bin:/usr/bin'
    export PATH
    '$ROOT_DIR/spells/.arcana/ai-dev/select-llm-to-install' 2>&1
  "
  assert_failure || return 1
  assert_error_contains "menu" || return 1
}

run_test_case "select-llm-to-install shows help" test_help
run_test_case "select-llm-to-install requires menu command" test_requires_menu

finish_tests
