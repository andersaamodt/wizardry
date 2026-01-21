#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_requires_keys() {
  run_cmd "$ROOT_DIR/spells/.imps/test/socat-send-keys"
  assert_failure || return 1
  assert_error_contains "keys required" || return 1
}

test_converts_enter() {
  output=$("$ROOT_DIR/spells/.imps/test/socat-send-keys" enter | od -An -tx1)
  # Enter should be \r (0d in hex)
  case "$output" in
    *0d*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="expected 0d (carriage return) in output, got: $output"
      return 1
      ;;
  esac
}

test_converts_arrow_keys() {
  output=$("$ROOT_DIR/spells/.imps/test/socat-send-keys" up | od -An -tx1)
  # Up should be ESC[A (1b 5b 41 in hex)
  case "$output" in
    *1b*5b*41*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="expected 1b 5b 41 (ESC[A) in output, got: $output"
      return 1
      ;;
  esac
}

run_test_case "socat-send-keys requires keys" test_requires_keys
run_test_case "socat-send-keys converts enter to CR" test_converts_enter
run_test_case "socat-send-keys converts arrow keys" test_converts_arrow_keys
finish_tests
