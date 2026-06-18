#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/enable-mobile-tcpip-adb" --help
  assert_success
  assert_output_contains "Usage: enable-mobile-tcpip-adb"
}

switches_device_to_tcpip() {
  tmpdir=$(make_tempdir)

  cat >"$tmpdir/firewalled-adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"${ADB_LOG:?}"
if [ "$#" -ge 6 ] && [ "$5" = "tcpip" ] && [ "$6" = "5555" ]; then
  exit 0
fi
case " $* " in
  *" shell "*)
    printf '%s\n' "5555"
    exit 0
    ;;
esac
exit 0
SH
  chmod +x "$tmpdir/firewalled-adb"

  ADB_LOG="$tmpdir/adb.log" run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    ADB_LOG="$tmpdir/adb.log" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/enable-mobile-tcpip-adb" \
    --serial 192.168.1.164:35149

  assert_success || return 1
  assert_file_contains "$tmpdir/adb.log" "--serial"
  assert_file_contains "$tmpdir/adb.log" "192.168.1.164:35149"
  assert_file_contains "$tmpdir/adb.log" "tcpip"
  assert_file_contains "$tmpdir/adb.log" "5555"
  assert_output_contains "Android adb TCP/IP is now listening on 192.168.1.164:5555"
  assert_output_contains "setup-mobile-tor-adb --serial 192.168.1.164:35149"
}

rejects_bad_port() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/enable-mobile-tcpip-adb" \
    --serial 192.168.1.164:35149 \
    --port nope

  assert_failure
  assert_error_contains "--port must be numeric"
}

run_test_case "enable-mobile-tcpip-adb shows help" shows_help
run_test_case "enable-mobile-tcpip-adb switches device to tcpip" switches_device_to_tcpip
run_test_case "enable-mobile-tcpip-adb rejects bad port" rejects_bad_port

finish_tests
