#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_spell "spells/.arcana/mobile-debugging/uninstall-maestro-cli" --help
  assert_success || return 1
  assert_output_contains "Usage: uninstall-maestro-cli" || return 1
}

removes_theurgy_and_legacy_roots() {
  tmpdir=$(make_tempdir)
  data_home="$tmpdir/data"
  current_root="$data_home/theurgy/mobile-debugging/maestro-cli/current/bin"
  legacy_root="$data_home/wizardry/mobile-debugging/maestro-cli/current/bin"
  mkdir -p "$current_root" "$legacy_root"
  : >"$current_root/maestro"
  : >"$legacy_root/maestro"

  run_cmd env XDG_DATA_HOME="$data_home" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/uninstall-maestro-cli"

  assert_success || return 1
  assert_output_contains "Removed Maestro CLI from Theurgy quarantine roots" || return 1
  assert_path_missing "$data_home/theurgy/mobile-debugging/maestro-cli" || return 1
  assert_path_missing "$data_home/wizardry/mobile-debugging/maestro-cli" || return 1
}

reports_when_not_installed() {
  tmpdir=$(make_tempdir)
  data_home="$tmpdir/data"

  run_cmd env XDG_DATA_HOME="$data_home" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/uninstall-maestro-cli"

  assert_success || return 1
  assert_path_missing "$data_home/theurgy/mobile-debugging/maestro-cli" || return 1
  assert_path_missing "$data_home/wizardry/mobile-debugging/maestro-cli" || return 1
}

run_test_case "uninstall-maestro-cli shows help" shows_help
run_test_case "uninstall-maestro-cli removes current and legacy roots" \
  removes_theurgy_and_legacy_roots
run_test_case "uninstall-maestro-cli reports missing install" reports_when_not_installed

finish_tests
