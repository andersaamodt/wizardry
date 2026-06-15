#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_cmd "$ROOT_DIR/spells/wards/firewalled-maestro" --help
  assert_success
  assert_output_contains "Usage: firewalled-maestro"
}

routes_adb_through_firewalled_adb() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/bin"
  data_home="$tmpdir/data"
  mkdir -p "$stub_dir" "$data_home/wizardry/mobile-debugging/maestro-cli/current/bin"

  cat >"$data_home/wizardry/mobile-debugging/maestro-cli/current/bin/maestro" <<'SH'
#!/bin/sh
adb devices
SH
  chmod +x "$data_home/wizardry/mobile-debugging/maestro-cli/current/bin/maestro"

  cat >"$stub_dir/firewalled-adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${FIREWALLED_ADB_LOG:?}"
exit 0
SH
  chmod +x "$stub_dir/firewalled-adb"

  run_cmd env PATH="$stub_dir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" XDG_DATA_HOME="$data_home" FIREWALLED_ADB_LOG="$tmpdir/firewalled-adb.log" \
    "$ROOT_DIR/spells/wards/firewalled-maestro" --serial 192.168.1.9:5555 --allow 192.168.1.10 -- devices

  assert_success || return 1
  assert_file_contains "$tmpdir/firewalled-adb.log" "--serial"
  assert_file_contains "$tmpdir/firewalled-adb.log" "192.168.1.9:5555"
  assert_file_contains "$tmpdir/firewalled-adb.log" "--allow"
  assert_file_contains "$tmpdir/firewalled-adb.log" "192.168.1.10"
  assert_file_contains "$tmpdir/firewalled-adb.log" "devices"
}

run_test_case "firewalled-maestro shows help" shows_help
run_test_case "firewalled-maestro routes adb through firewalled-adb" routes_adb_through_firewalled_adb

finish_tests
