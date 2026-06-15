#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_spell spells/wards/firewalled-adb --help
  assert_success
  assert_output_contains "Usage: firewalled-adb"
}

outer_wrapper_uses_firewall_and_serial_allowlist() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data"
  mkdir -p "$sdk_root/wizardry/mobile-debugging/android-sdk/platform-tools"

  cat >"$sdk_root/wizardry/mobile-debugging/android-sdk/platform-tools/adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"${ADB_LOG:?}"
exit 0
SH
  chmod +x "$sdk_root/wizardry/mobile-debugging/android-sdk/platform-tools/adb"

  cat >"$tmpdir/firewall" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${FIREWALL_LOG:?}"
while [ "$#" -gt 0 ]; do
  [ "$1" = "--" ] && break
  shift
done
shift
exec "$@"
SH
  chmod +x "$tmpdir/firewall"

  FIREWALL_LOG="$tmpdir/firewall.log" ADB_LOG="$tmpdir/adb.log" run_cmd env XDG_DATA_HOME="$sdk_root" PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" FIREWALL_LOG="$tmpdir/firewall.log" ADB_LOG="$tmpdir/adb.log" \
    "$ROOT_DIR/spells/wards/firewalled-adb" --serial 127.0.0.1:5555 -- shell getprop ro.product.model

  assert_success || return 1
  assert_file_contains "$tmpdir/firewall.log" "--allow-localhost"
  assert_file_contains "$tmpdir/firewall.log" "127.0.0.1:5555"
  assert_file_contains "$tmpdir/adb.log" "connect"
  assert_file_contains "$tmpdir/adb.log" "-s"
}

version_without_serial_does_not_trip_linebreak_guard() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data"
  mkdir -p "$sdk_root/wizardry/mobile-debugging/android-sdk/platform-tools"

  cat >"$sdk_root/wizardry/mobile-debugging/android-sdk/platform-tools/adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"${ADB_LOG:?}"
exit 0
SH
  chmod +x "$sdk_root/wizardry/mobile-debugging/android-sdk/platform-tools/adb"

  cat >"$tmpdir/firewall" <<'SH'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  [ "$1" = "--" ] && break
  shift
done
shift
exec "$@"
SH
  chmod +x "$tmpdir/firewall"

  ADB_LOG="$tmpdir/adb.log" run_cmd env XDG_DATA_HOME="$sdk_root" PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" ADB_LOG="$tmpdir/adb.log" \
    "$ROOT_DIR/spells/wards/firewalled-adb" -- version

  assert_success || return 1
  assert_file_contains "$tmpdir/adb.log" "version"
}

run_test_case "firewalled-adb shows help" shows_help
run_test_case "firewalled-adb uses firewall and serial allowlist" outer_wrapper_uses_firewall_and_serial_allowlist
run_test_case "firewalled-adb version works without serial" version_without_serial_does_not_trip_linebreak_guard

finish_tests
