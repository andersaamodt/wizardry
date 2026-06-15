#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_spell spells/wards/firewalled-maestro-tor --help
  assert_success
  assert_output_contains "Usage: firewalled-maestro-tor"
}

starts_forward_and_uses_firewalled_maestro() {
  tmpdir=$(make_tempdir)

  cat >"$tmpdir/tor-adb-forward" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${FORWARD_LOG:?}"
trap 'exit 0' TERM INT HUP
while :; do sleep 1; done
SH
  chmod +x "$tmpdir/tor-adb-forward"

  cat >"$tmpdir/firewalled-maestro" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${MAESTRO_LOG:?}"
exit 0
SH
  chmod +x "$tmpdir/firewalled-maestro"

  cat >"$tmpdir/nc" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmpdir/nc"

  FORWARD_LOG="$tmpdir/forward.log" MAESTRO_LOG="$tmpdir/maestro.log" run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" FORWARD_LOG="$tmpdir/forward.log" MAESTRO_LOG="$tmpdir/maestro.log" \
    "$ROOT_DIR/spells/wards/firewalled-maestro-tor" --onion abcdefghijklmnop.onion:5555 --local-port 19002 --socks 127.0.0.1:19050 -- test flow.yaml

  assert_success || return 1
  assert_file_contains "$tmpdir/forward.log" "abcdefghijklmnop.onion:5555"
  assert_file_contains "$tmpdir/forward.log" "19002"
  assert_file_contains "$tmpdir/maestro.log" "--serial"
  assert_file_contains "$tmpdir/maestro.log" "127.0.0.1:19002"
  assert_file_contains "$tmpdir/maestro.log" "--allow"
  assert_file_contains "$tmpdir/maestro.log" "test"
}

run_test_case "firewalled-maestro-tor shows help" shows_help
run_test_case "firewalled-maestro-tor starts forward and delegates" starts_forward_and_uses_firewalled_maestro

finish_tests
