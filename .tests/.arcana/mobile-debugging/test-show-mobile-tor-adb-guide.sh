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
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/show-mobile-tor-adb-guide"
  assert_success || return 1
  assert_output_contains "pkg install tor"
  assert_output_contains 'wizardry-tor-adb-start.sh'
  assert_output_contains 'adb_port=$(getprop service.adb.tcp.port'
  assert_output_contains 'adb_port=$(getprop service.adb.tls.port'
  assert_output_contains "wireless_host='PHONE_WIFI_IP'"
  assert_output_contains 'candidate_hosts_file="$state_dir/adb-host-candidates.txt"'
  assert_output_contains 'append_candidate_host "$wireless_host"'
  assert_output_contains 'ip route get 1.1.1.1'
  assert_output_contains 'nc -z "$candidate_host" "$adb_port"'
  assert_output_contains 'termux-wake-lock >/dev/null 2>&1 || true'
  assert_output_contains 'tor --RunAsDaemon 1 -f "$torrc" >"$log_file" 2>&1'
  assert_output_contains 'HiddenServicePort 5555 __ADB_TARGET__'
  assert_output_contains "firewalled-adb-tor --onion"
  assert_output_contains "firewalled-maestro-tor --onion"
  assert_output_contains "boot hook lets Termux re-resolve the"
}

prints_explicit_override() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/show-mobile-tor-adb-guide" 127.0.0.1:47000
  assert_success || return 1
  assert_output_contains "adb_target='127.0.0.1:47000'"
}

run_test_case "show-mobile-tor-adb-guide shows help" shows_help
run_test_case "show-mobile-tor-adb-guide prints commands" prints_termux_and_host_commands
run_test_case "show-mobile-tor-adb-guide prints override target" prints_explicit_override

finish_tests
