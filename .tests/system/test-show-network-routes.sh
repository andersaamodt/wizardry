#!/bin/sh
# Behavioral cases:
# - show-network-routes shows usage
# - show-network-routes prefers netstat -rn
# - show-network-routes falls back to ip route show

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/system/show-network-routes" --help
  assert_success || return 1
  assert_output_contains "Usage: show-network-routes" || return 1
}

test_prefers_netstat() {
  tmp=$(make_tempdir)
  cat >"$tmp/netstat" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >"$NETSTAT_LOG"
printf '%s\n' "netstat-ran"
SH
  chmod +x "$tmp/netstat"

  run_cmd env PATH="$tmp:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin" NETSTAT_LOG="$tmp/log" \
    "$ROOT_DIR/spells/system/show-network-routes"
  assert_success || return 1
  assert_output_contains "netstat-ran" || return 1
  assert_file_contains "$tmp/log" "-rn"
}

test_falls_back_to_ip() {
  tmp=$(make_tempdir)
  cat >"$tmp/ip" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >"$IP_LOG"
printf '%s\n' "ip-ran"
SH
  chmod +x "$tmp/ip"

  run_cmd env PATH="$tmp:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips" IP_LOG="$tmp/log" \
    "$ROOT_DIR/spells/system/show-network-routes"
  assert_success || return 1
  assert_output_contains "ip-ran" || return 1
  assert_file_contains "$tmp/log" "route show"
}

run_test_case "show-network-routes shows usage" test_help
run_test_case "show-network-routes prefers netstat" test_prefers_netstat
run_test_case "show-network-routes falls back to ip" test_falls_back_to_ip

finish_tests
