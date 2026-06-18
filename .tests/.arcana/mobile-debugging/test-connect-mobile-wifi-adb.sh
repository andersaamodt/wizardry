#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/connect-mobile-wifi-adb" --help
  assert_success
  assert_output_contains "Usage: connect-mobile-wifi-adb"
}

connects_unique_discovered_endpoint() {
  tmpdir=$(make_tempdir)
  adb_dir="$tmpdir/data/theurgy/mobile-debugging/android-sdk/platform-tools"
  mkdir -p "$adb_dir" "$tmpdir/bin"

  cat >"$adb_dir/adb" <<'SH'
#!/bin/sh
if [ "${1-}" = "mdns" ] && [ "${2-}" = "services" ]; then
  printf '%s\n' "adb-44041JEKB09055-AY981N _adb-tls-connect._tcp 192.168.1.164:35149"
  exit 0
fi
exit 1
SH
  chmod +x "$adb_dir/adb"

  cat >"$tmpdir/bin/firewalled-adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${ADB_LOG:?}"
exit 0
SH
  chmod +x "$tmpdir/bin/firewalled-adb"

  ADB_LOG="$tmpdir/adb.log" run_cmd env PATH="$tmpdir/bin:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    XDG_DATA_HOME="$tmpdir/data" ADB_LOG="$tmpdir/adb.log" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/connect-mobile-wifi-adb"

  assert_success || return 1
  assert_file_contains "$tmpdir/adb.log" "--allow"
  assert_file_contains "$tmpdir/adb.log" "192.168.1.164:35149"
  assert_file_contains "$tmpdir/adb.log" "connect"
  assert_output_contains "Connected to 192.168.1.164:35149"
}

rejects_ambiguous_results_without_filter() {
  tmpdir=$(make_tempdir)
  adb_dir="$tmpdir/data/theurgy/mobile-debugging/android-sdk/platform-tools"
  mkdir -p "$adb_dir" "$tmpdir/bin"

  cat >"$adb_dir/adb" <<'SH'
#!/bin/sh
if [ "${1-}" = "mdns" ] && [ "${2-}" = "services" ]; then
  printf '%s\n' "adb-ONE _adb-tls-connect._tcp 192.168.1.164:35149"
  printf '%s\n' "adb-TWO _adb-tls-connect._tcp 192.168.1.165:33333"
  exit 0
fi
exit 1
SH
  chmod +x "$adb_dir/adb"

  cat >"$tmpdir/bin/firewalled-adb" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmpdir/bin/firewalled-adb"

  run_cmd env PATH="$tmpdir/bin:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" XDG_DATA_HOME="$tmpdir/data" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/connect-mobile-wifi-adb"

  assert_failure
  assert_error_contains "multiple matching wireless-debugging endpoints"
}

filters_by_ip() {
  tmpdir=$(make_tempdir)
  adb_dir="$tmpdir/data/theurgy/mobile-debugging/android-sdk/platform-tools"
  mkdir -p "$adb_dir" "$tmpdir/bin"

  cat >"$adb_dir/adb" <<'SH'
#!/bin/sh
if [ "${1-}" = "mdns" ] && [ "${2-}" = "services" ]; then
  printf '%s\n' "adb-ONE _adb-tls-connect._tcp 192.168.1.164:35149"
  printf '%s\n' "adb-TWO _adb-tls-connect._tcp 192.168.1.165:33333"
  exit 0
fi
exit 1
SH
  chmod +x "$adb_dir/adb"

  cat >"$tmpdir/bin/firewalled-adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${ADB_LOG:?}"
exit 0
SH
  chmod +x "$tmpdir/bin/firewalled-adb"

  ADB_LOG="$tmpdir/adb.log" run_cmd env PATH="$tmpdir/bin:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    XDG_DATA_HOME="$tmpdir/data" ADB_LOG="$tmpdir/adb.log" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/connect-mobile-wifi-adb" --ip 192.168.1.165

  assert_success || return 1
  assert_file_contains "$tmpdir/adb.log" "192.168.1.165:33333"
  assert_output_contains "Connected to 192.168.1.165:33333"
}

run_test_case "connect-mobile-wifi-adb shows help" shows_help
run_test_case "connect-mobile-wifi-adb connects unique discovered endpoint" connects_unique_discovered_endpoint
run_test_case "connect-mobile-wifi-adb rejects ambiguous discovery without filter" rejects_ambiguous_results_without_filter
run_test_case "connect-mobile-wifi-adb filters by ip" filters_by_ip

finish_tests
