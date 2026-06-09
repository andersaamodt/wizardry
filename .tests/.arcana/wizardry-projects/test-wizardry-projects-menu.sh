#!/bin/sh
# Behavioral coverage for wizardry-projects-menu.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/wizardry-projects/wizardry-projects-menu"

test_wizardry_projects_menu_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: wizardry-projects-menu" || return 1
}

test_wizardry_projects_menu_executable() {
  [ -x "$ROOT_DIR/$target" ] || {
    TEST_FAILURE_REASON="expected executable menu spell"
    return 1
  }
}

test_wizardry_projects_menu_syntax_valid() {
  run_cmd sh -n "$ROOT_DIR/$target"
  assert_success || return 1
}

run_test_case "wizardry-projects-menu shows help" test_wizardry_projects_menu_help
run_test_case "wizardry-projects-menu is executable" test_wizardry_projects_menu_executable
run_test_case "wizardry-projects-menu syntax is valid" test_wizardry_projects_menu_syntax_valid

finish_tests
