#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - wallet-menu prompts to install when bitcoin is absent
# - wallet-menu shows wallet controls when bitcoin is installed
# - wallet-menu shows daemon controls based on running state

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

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

test_wallet_menu_prompts_install_when_missing() {
  tmp=$(make_tempdir)
  write-stub-menu "$tmp"
  write-stub-colors "$tmp"
  write-stub-exit-label "$tmp"
  make_status_stub "$tmp" "missing"
  make_boolean_stub "$tmp/is-bitcoin-installed" 1
  make_boolean_stub "$tmp/is-service-installed" 1
  make_boolean_stub "$tmp/is-bitcoin-running" 1

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/.arcana/bitcoin/wallet-menu"
  assert_success
  assert_file_contains "$tmp/log" "Bitcoin: missing"
  assert_file_contains "$tmp/log" "Install or Upgrade Bitcoin%install-bitcoin"
}

test_wallet_menu_shows_wallet_controls_when_installed() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  write-stub-menu "$tmp"
  write-stub-colors "$tmp"
  write-stub-exit-label "$tmp"
  make_status_stub "$tmp" "ready"
  make_boolean_stub "$tmp/is-bitcoin-installed" 0
  make_boolean_stub "$tmp/is-service-installed" 1
  make_boolean_stub "$tmp/is-bitcoin-running" 0

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/.arcana/bitcoin/wallet-menu"
  assert_success
  assert_file_contains "$tmp/log" "Check Wallet Balance"
  assert_file_contains "$tmp/log" "Get New Receive Address"
  assert_file_contains "$tmp/log" "Send Bitcoin"
  assert_file_contains "$tmp/log" "Uninstall Bitcoin%uninstall-bitcoin"
}

test_wallet_menu_shows_stop_when_running() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  write-stub-menu "$tmp"
  write-stub-colors "$tmp"
  write-stub-exit-label "$tmp"
  make_status_stub "$tmp" "ready"
  make_boolean_stub "$tmp/is-bitcoin-installed" 0
  make_boolean_stub "$tmp/is-service-installed" 1
  make_boolean_stub "$tmp/is-bitcoin-running" 0

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/.arcana/bitcoin/wallet-menu"
  assert_success
  assert_file_contains "$tmp/log" "Stop bitcoind%bitcoin-cli stop"
}

run_test_case "wallet-menu prompts for install when missing" test_wallet_menu_prompts_install_when_missing
run_test_case "wallet-menu shows wallet controls when installed" test_wallet_menu_shows_wallet_controls_when_installed
run_test_case "wallet-menu shows stop when daemon running" test_wallet_menu_shows_stop_when_running

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/.arcana/bitcoin/wallet-menu" --help
  assert_success
  assert_output_contains "Usage: wallet-menu"
}

run_test_case "wallet-menu --help shows usage" test_shows_help

finish_tests
