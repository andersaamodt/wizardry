#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_requires_command() {
  run_cmd "$ROOT_DIR/spells/.imps/test/socat-pty"
  assert_failure || return 1
  assert_error_contains "command required" || return 1
}

test_requires_socat() {
  # Only run if socat is not installed
  if command -v socat >/dev/null 2>&1; then
    test_skip "requires socat to be missing"
    return 0
  fi
  
  run_cmd "$ROOT_DIR/spells/.imps/test/socat-pty" echo "test"
  assert_failure || return 1
  assert_error_contains "socat not found" || return 1
}

run_test_case "socat-pty requires command" test_requires_command
run_test_case "socat-pty requires socat installed" test_requires_socat
finish_tests
