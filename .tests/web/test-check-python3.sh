#!/bin/sh
# Behavioral coverage for check-python3.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/check-python3"

test_check_python3_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: check-python3" || return 1
}

test_check_python3_executable() {
  [ -x "$ROOT_DIR/$target" ] || {
    TEST_FAILURE_REASON="expected executable check-python3 spell"
    return 1
  }
}

test_check_python3_reports_status() {
  run_cmd sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "status=" || return 1
}

run_test_case "check-python3 shows help" test_check_python3_help
run_test_case "check-python3 is executable" test_check_python3_executable
run_test_case "check-python3 reports status" test_check_python3_reports_status

finish_tests
