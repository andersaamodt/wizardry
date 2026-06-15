#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_spell spells/wards/firewalled-adb-tor --help
  assert_success
  assert_output_contains "Usage: firewalled-adb-tor"
}

starts_forward_and_uses_firewalled_adb() {
  tmpdir=$(make_tempdir)

  cat >"$tmpdir/tor-adb-forward" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${FORWARD_LOG:?}"
trap 'exit 0' TERM INT HUP
while :; do sleep 1; done
SH
  chmod +x "$tmpdir/tor-adb-forward"

  cat >"$tmpdir/firewalled-adb" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${ADB_LOG:?}"
exit 0
SH
  chmod +x "$tmpdir/firewalled-adb"

  cat >"$tmpdir/nc" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmpdir/nc"

  FORWARD_LOG="$tmpdir/forward.log" ADB_LOG="$tmpdir/adb.log" run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" FORWARD_LOG="$tmpdir/forward.log" ADB_LOG="$tmpdir/adb.log" \
    "$ROOT_DIR/spells/wards/firewalled-adb-tor" --onion abcdefghijklmnop.onion:5555 --local-port 19001 --socks 127.0.0.1:19050 -- shell input keyevent 3

  assert_success || return 1
  assert_file_contains "$tmpdir/forward.log" "--onion"
  assert_file_contains "$tmpdir/forward.log" "abcdefghijklmnop.onion:5555"
  assert_file_contains "$tmpdir/forward.log" "--local-port"
  assert_file_contains "$tmpdir/forward.log" "19001"
  assert_file_contains "$tmpdir/adb.log" "--serial"
  assert_file_contains "$tmpdir/adb.log" "127.0.0.1:19001"
  assert_file_contains "$tmpdir/adb.log" "--allow"
  assert_file_contains "$tmpdir/adb.log" "shell"
}

run_test_case "firewalled-adb-tor shows help" shows_help
run_test_case "firewalled-adb-tor starts forward and delegates" starts_forward_and_uses_firewalled_adb

finish_tests
