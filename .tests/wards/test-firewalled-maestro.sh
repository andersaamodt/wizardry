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

starts_persistent_adb_server_and_exports_android_sdk() {
  tmpdir=$(make_tempdir)

  cat >"$tmpdir/maestro" <<'SH'
#!/bin/sh
{
  printf '%s\n' "$ANDROID_HOME"
  printf '%s\n' "${ADB_SERVER_PORT:-}"
  printf '%s\n' "${ANDROID_ADB_SERVER_PORT:-}"
  printf '%s\n' "${ANDROID_SERIAL:-}"
} >"${MAESTRO_ENV_LOG:?}"
"$ANDROID_HOME/platform-tools/adb" devices
SH
  chmod +x "$tmpdir/maestro"

  cat >"$tmpdir/adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"${ADB_LOG:?}"
case " $* " in
  *" server nodaemon "*)
    trap 'exit 0' TERM INT HUP
    while :; do sleep 1; done
    ;;
esac
exit 0
SH
  chmod +x "$tmpdir/adb"

  cat >"$tmpdir/firewall" <<'SH'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  case "$1" in
    --)
      shift
      break
      ;;
    *)
      shift
      ;;
  esac
done
exec "$@"
SH
  chmod +x "$tmpdir/firewall"

  MAESTRO_ENV_LOG="$tmpdir/maestro-env.log" ADB_LOG="$tmpdir/adb.log" run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" MAESTRO_ENV_LOG="$tmpdir/maestro-env.log" ADB_LOG="$tmpdir/adb.log" \
    "$ROOT_DIR/spells/wards/firewalled-maestro" --serial 127.0.0.1:15555 --allow 127.0.0.1:15555 -- list-devices

  assert_success || return 1
  assert_file_contains "$tmpdir/maestro-env.log" "firewalled-maestro"
  assert_file_contains "$tmpdir/maestro-env.log" "127.0.0.1:15555"
  assert_file_contains "$tmpdir/adb.log" "-L"
  assert_file_contains "$tmpdir/adb.log" "tcp:localhost:"
  assert_file_contains "$tmpdir/adb.log" "-P"
  assert_file_contains "$tmpdir/adb.log" "nodaemon"
  assert_file_contains "$tmpdir/adb.log" "server"
  assert_file_contains "$tmpdir/adb.log" "connect"
  assert_file_contains "$tmpdir/adb.log" "devices"
}

run_test_case "firewalled-maestro shows help" shows_help
run_test_case "firewalled-maestro starts persistent adb server and exports Android SDK" starts_persistent_adb_server_and_exports_android_sdk

finish_tests
