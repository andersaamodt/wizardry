#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_spell spells/wards/firewalled-maestro --help
  assert_success
  assert_output_contains "Usage: firewalled-maestro"
}

exposes_adb_shim_as_android_sdk() {
  tmpdir=$(make_tempdir)

  cat >"$tmpdir/maestro" <<'SH'
#!/bin/sh
printf '%s\n' "$ANDROID_HOME" >"${MAESTRO_ENV_LOG:?}"
"$ANDROID_HOME/platform-tools/adb" devices
SH
  chmod +x "$tmpdir/maestro"

  cat >"$tmpdir/firewalled-adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${ADB_LOG:?}"
exit 0
SH
  chmod +x "$tmpdir/firewalled-adb"

  MAESTRO_ENV_LOG="$tmpdir/maestro-env.log" ADB_LOG="$tmpdir/adb.log" run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" MAESTRO_ENV_LOG="$tmpdir/maestro-env.log" ADB_LOG="$tmpdir/adb.log" \
    "$ROOT_DIR/spells/wards/firewalled-maestro" --serial 127.0.0.1:15555 --allow 127.0.0.1:15555 -- list-devices

  assert_success || return 1
  assert_file_contains "$tmpdir/maestro-env.log" "firewalled-maestro"
  assert_file_contains "$tmpdir/adb.log" "--serial"
  assert_file_contains "$tmpdir/adb.log" "127.0.0.1:15555"
  assert_file_contains "$tmpdir/adb.log" "--allow"
  assert_file_contains "$tmpdir/adb.log" "devices"
}

run_test_case "firewalled-maestro shows help" shows_help
run_test_case "firewalled-maestro exposes adb shim as Android SDK" exposes_adb_shim_as_android_sdk

finish_tests
