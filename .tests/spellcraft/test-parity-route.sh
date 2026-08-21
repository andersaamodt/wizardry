#!/bin/sh
# Behavioral cases for parity-route:
# - shows help
# - rejects missing authorization
# - preserves manual gates
# - chooses the lowest eligible device id

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

parity_route_shows_help() {
  run_spell "spells/spellcraft/parity-route" --help
  assert_success || return 1
  assert_output_contains "Usage: parity-route" || return 1
}

parity_route_rejects_missing_scope() {
  devices="$ROOT_DIR/spells/spellcraft/.parity/example-devices.tsv"
  run_spell "spells/spellcraft/parity-route" mobile_debug_control \
    android_termux "$devices" device.debug lan
  assert_failure || return 1
  assert_output_contains "status=rejected" || return 1
  assert_output_contains "device.control" || return 1
}

parity_route_preserves_manual_gate() {
  devices="$ROOT_DIR/spells/spellcraft/.parity/example-devices.tsv"
  run_spell "spells/spellcraft/parity-route" mobile_debug_control \
    android_termux "$devices" device.debug,device.control lan
  assert_success || return 1
  assert_output_contains "status=manual_gate" || return 1
  assert_output_contains "wifi_debugging_enabled" || return 1
}

parity_route_selects_stably() {
  tmpdir=$(make_tempdir)
  devices=$tmpdir/devices.tsv
  cat >"$devices" <<'EOF'
# id	platform	transports	required_prerequisites	satisfied_prerequisites
z-phone	android_termux	lan	-	wifi_debugging_enabled
a-phone	android_termux	lan,tor	-	wifi_debugging_enabled
EOF
  run_spell "spells/spellcraft/parity-route" mobile_debug_control \
    android_termux "$devices" device.debug,device.control tor,lan
  assert_success || return 1
  assert_output_contains "status=eligible" || return 1
  assert_output_contains "device=a-phone" || return 1
  assert_output_contains "transport=tor" || return 1
}

run_test_case "parity-route shows help" parity_route_shows_help
run_test_case "parity-route rejects missing scope" parity_route_rejects_missing_scope
run_test_case "parity-route preserves manual gate" parity_route_preserves_manual_gate
run_test_case "parity-route selects stably" parity_route_selects_stably

finish_tests
