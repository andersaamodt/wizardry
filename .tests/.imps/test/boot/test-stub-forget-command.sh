#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_stub_forget_command_exists() {
  [ -f "$ROOT_DIR/spells/.imps/test/boot/stub-forget-command" ]
}

test_stub_forget_command_is_readable() {
  [ -r "$ROOT_DIR/spells/.imps/test/boot/stub-forget-command" ]
}

run_test_case "stub-forget-command exists" test_stub_forget_command_exists
run_test_case "stub-forget-command is readable" test_stub_forget_command_is_readable

finish_tests
