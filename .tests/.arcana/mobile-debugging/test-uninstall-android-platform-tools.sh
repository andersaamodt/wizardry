#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_spell "spells/.arcana/mobile-debugging/uninstall-android-platform-tools" --help
  assert_success || return 1
  assert_output_contains "Usage: uninstall-android-platform-tools" || return 1
}

removes_theurgy_and_legacy_roots() {
  tmpdir=$(make_tempdir)
  data_home="$tmpdir/data"
  current_root="$data_home/theurgy/mobile-debugging/android-sdk/platform-tools"
  legacy_root="$data_home/wizardry/mobile-debugging/android-sdk/platform-tools"
  mkdir -p "$current_root" "$legacy_root"
  : >"$current_root/adb"
  : >"$legacy_root/adb"

  run_cmd env XDG_DATA_HOME="$data_home" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/uninstall-android-platform-tools"

  assert_success || return 1
  assert_output_contains "Removed Android platform tools from Theurgy quarantine roots" || return 1
  assert_path_missing "$data_home/theurgy/mobile-debugging/android-sdk" || return 1
  assert_path_missing "$data_home/wizardry/mobile-debugging/android-sdk" || return 1
}

reports_when_not_installed() {
  tmpdir=$(make_tempdir)
  data_home="$tmpdir/data"

  run_cmd env XDG_DATA_HOME="$data_home" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/uninstall-android-platform-tools"

  assert_success || return 1
  assert_path_missing "$data_home/theurgy/mobile-debugging/android-sdk" || return 1
  assert_path_missing "$data_home/wizardry/mobile-debugging/android-sdk" || return 1
}

run_test_case "uninstall-android-platform-tools shows help" shows_help
run_test_case "uninstall-android-platform-tools removes current and legacy roots" \
  removes_theurgy_and_legacy_roots
run_test_case "uninstall-android-platform-tools reports missing install" reports_when_not_installed

finish_tests
