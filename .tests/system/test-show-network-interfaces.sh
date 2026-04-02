#!/bin/sh
# Behavioral cases:
# - show-network-interfaces shows usage
# - show-network-interfaces prefers ifconfig
# - show-network-interfaces falls back to ip addr show

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/system/show-network-interfaces" --help
  assert_success || return 1
  assert_output_contains "Usage: show-network-interfaces" || return 1
}

test_prefers_ifconfig() {
  tmp=$(make_tempdir)
  cat >"$tmp/ifconfig" <<'SH'
#!/bin/sh
printf '%s\n' "ifconfig-ran"
SH
  chmod +x "$tmp/ifconfig"

  run_cmd env PATH="$tmp:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin" \
    "$ROOT_DIR/spells/system/show-network-interfaces"
  assert_success || return 1
  assert_output_contains "ifconfig-ran" || return 1
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
    "$ROOT_DIR/spells/system/show-network-interfaces"
  assert_success || return 1
  assert_output_contains "ip-ran" || return 1
  assert_file_contains "$tmp/log" "addr show"
}

run_test_case "show-network-interfaces shows usage" test_help
run_test_case "show-network-interfaces prefers ifconfig" test_prefers_ifconfig
run_test_case "show-network-interfaces falls back to ip" test_falls_back_to_ip

finish_tests
