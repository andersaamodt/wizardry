#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/show-mobile-tor-adb-guide" --help
  assert_success
  assert_output_contains "Usage: show-mobile-tor-adb-guide"
}

prints_termux_and_host_commands() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/show-mobile-tor-adb-guide" 192.168.1.159:34897
  assert_success || return 1
  assert_output_contains "pkg install tor"
  assert_output_contains "HiddenServicePort 5555 192.168.1.159:34897"
  assert_output_contains "firewalled-adb-tor --onion"
  assert_output_contains "firewalled-maestro-tor --onion"
}

run_test_case "show-mobile-tor-adb-guide shows help" shows_help
run_test_case "show-mobile-tor-adb-guide prints commands" prints_termux_and_host_commands

finish_tests
