#!/bin/sh
# Tests for the zsh command-not-found handler imp

# Locate the repository root so we can source test-bootstrap
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

handler_path="$ROOT_DIR/spells/.imps/sys/command-not-found-handler-zsh"

test_handler_defines_function() {
  _run_cmd sh -c ". \"$handler_path\"; command -v command_not_found_handler >/dev/null"
  _assert_success
}

test_handler_returns_127() {
  _run_cmd env HANDLER_PATH="$handler_path" ROOT_DIR="$ROOT_DIR" sh -c '
    . "$HANDLER_PATH"
    WIZARDRY_DIR="$ROOT_DIR"
    export WIZARDRY_DIR
    if command_not_found_handler wizardry_nope >/dev/null 2>&1; then
      status=0
    else
      status=$?
    fi
    printf "%s\n" "$status"
  '
  _assert_success
  _assert_output_contains "127"
}

_run_test_case "command_not_found_handler defines function" test_handler_defines_function
_run_test_case "command_not_found_handler returns 127" test_handler_returns_127

_finish_tests
