#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - bitcoin-menu prompts to install when bitcoin is absent
# - bitcoin-menu offers service controls when running under systemd
# - bitcoin-menu offers service installation when bitcoin is present without a service

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -s INT "$PPID"
exit 0
SH
  chmod +x "$tmp/menu"
}

make_stub_colors() {
  tmp=$1
  cat >"$tmp/colors" <<'SH'
#!/bin/sh
BOLD=""
CYAN=""
SH
  chmod +x "$tmp/colors"
}

make_status_stub() {
  tmp=$1
  status=$2
  cat >"$tmp/bitcoin-status" <<SH
#!/bin/sh
echo "$status"
SH
  chmod +x "$tmp/bitcoin-status"
}

make_boolean_stub() {
  path=$1
  exit_code=$2
  cat >"$path" <<SH
#!/bin/sh
exit $exit_code
SH
  chmod +x "$path"
}

test_bitcoin_menu_prompts_install_when_missing() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  make_status_stub "$tmp" "missing"
  make_boolean_stub "$tmp/is-bitcoin-installed" 1
  make_boolean_stub "$tmp/is-service-installed" 1
  make_boolean_stub "$tmp/is-bitcoin-running" 1

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/install/bitcoin/bitcoin-menu"
  assert_success
  assert_file_contains "$tmp/log" "Bitcoin: missing"
  assert_file_contains "$tmp/log" "Install Bitcoin%install-bitcoin"
}

test_bitcoin_menu_controls_running_service() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  make_status_stub "$tmp" "ready"
  make_boolean_stub "$tmp/is-bitcoin-installed" 0
  make_boolean_stub "$tmp/is-service-installed" 0
  make_boolean_stub "$tmp/is-bitcoin-running" 0

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/install/bitcoin/bitcoin-menu"
  assert_success
  assert_file_contains "$tmp/log" "Stop Bitcoin Service%sudo systemctl stop bitcoin"
  assert_file_contains "$tmp/log" "Uninstall Bitcoin Service%remove-service bitcoin"
  assert_file_contains "$tmp/log" "Uninstall Bitcoin%uninstall-bitcoin"
}

test_bitcoin_menu_offers_service_install_when_missing() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  make_status_stub "$tmp" "ready"
  make_boolean_stub "$tmp/is-bitcoin-installed" 0
  make_boolean_stub "$tmp/is-service-installed" 1
  make_boolean_stub "$tmp/is-bitcoin-running" 1
  cat >"$tmp/which" <<'SH'
#!/bin/sh
echo /usr/bin/bitcoind
SH
  chmod +x "$tmp/which"

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/install/bitcoin/bitcoin-menu"
  assert_success
  assert_file_contains "$tmp/log" "Install Bitcoin Service%install-service-template $ROOT_DIR/spells/install/bitcoin/bitcoin.service \"BITCOIND=/usr/bin/bitcoind\""
  assert_file_contains "$tmp/log" "Uninstall Bitcoin%uninstall-bitcoin"
}

run_test_case "bitcoin-menu prompts for install when missing" test_bitcoin_menu_prompts_install_when_missing
run_test_case "bitcoin-menu manages running services" test_bitcoin_menu_controls_running_service
run_test_case "bitcoin-menu installs service when absent" test_bitcoin_menu_offers_service_install_when_missing
finish_tests
