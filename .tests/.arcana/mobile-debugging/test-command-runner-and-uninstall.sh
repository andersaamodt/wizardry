#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

termux_runner_requires_its_envelope() {
  run_cmd sh "$ROOT_DIR/spells/.arcana/mobile-debugging/termux-command-runner"
  assert_status 2
}

termux_runner_records_complete_receipts() {
  runner=$ROOT_DIR/spells/.arcana/mobile-debugging/termux-command-runner
  grep -q 'stdout.txt' "$runner" &&
    grep -q 'stderr.txt' "$runner" &&
    grep -q 'exit-code.txt' "$runner"
}

android_commandline_uninstaller_shows_help() {
  run_spell spells/.arcana/mobile-debugging/uninstall-android-commandline-tools --help
  assert_success
}

run_test_case "Termux command runner requires its job envelope" termux_runner_requires_its_envelope
run_test_case "Termux command runner records complete receipts" termux_runner_records_complete_receipts
run_test_case "Android command-line tools uninstaller shows help" android_commandline_uninstaller_shows_help
finish_tests
