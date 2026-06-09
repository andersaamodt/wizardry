#!/bin/sh
# Behavioral coverage for install-python3.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/install-python3"

test_install_python3_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: install-python3" || return 1
}

test_install_python3_executable() {
  [ -x "$ROOT_DIR/$target" ] || {
    TEST_FAILURE_REASON="expected executable install-python3 spell"
    return 1
  }
}

test_install_python3_exits_when_present() {
  run_cmd sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "python3 is already installed" || return 1
}

run_test_case "install-python3 shows help" test_install_python3_help
run_test_case "install-python3 is executable" test_install_python3_executable
run_test_case "install-python3 exits when python3 is present" test_install_python3_exits_when_present

finish_tests
