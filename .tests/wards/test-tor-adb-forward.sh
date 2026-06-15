#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_spell spells/wards/tor-adb-forward --help
  assert_success
  assert_output_contains "Usage: tor-adb-forward"
}

rejects_non_onion_endpoint() {
  run_spell spells/wards/tor-adb-forward --onion example.com:5555
  assert_failure
  assert_error_contains "HOST.onion:PORT"
}

uses_firewall_and_socat_socks_forward() {
  tmpdir=$(make_tempdir)

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

  cat >"$tmpdir/socat" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${SOCAT_LOG:?}"
exit 0
SH
  chmod +x "$tmpdir/socat"

  FIREWALL_LOG="$tmpdir/firewall.log" SOCAT_LOG="$tmpdir/socat.log" run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" FIREWALL_LOG="$tmpdir/firewall.log" SOCAT_LOG="$tmpdir/socat.log" \
    "$ROOT_DIR/spells/wards/tor-adb-forward" --onion abcdefghijklmnop.onion:5555 --local-port 17777 --socks 127.0.0.1:19050

  assert_success || return 1
  assert_file_contains "$tmpdir/firewall.log" "--allow-localhost"
  assert_file_contains "$tmpdir/firewall.log" "127.0.0.1:19050"
  assert_file_contains "$tmpdir/socat.log" "TCP-LISTEN:17777,bind=127.0.0.1,reuseaddr,fork"
  assert_file_contains "$tmpdir/socat.log" "SOCKS4A:127.0.0.1:abcdefghijklmnop.onion:5555,socksport=19050"
}

run_test_case "tor-adb-forward shows help" shows_help
run_test_case "tor-adb-forward rejects non-onion endpoint" rejects_non_onion_endpoint
run_test_case "tor-adb-forward uses firewall and socat" uses_firewall_and_socat_socks_forward

finish_tests
