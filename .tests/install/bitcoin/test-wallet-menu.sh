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

make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -TERM "$PPID" 2>/dev/null || exit 0; exit 0
SH
  chmod +x "$tmp/menu"
}

make_stub_colors() {
  tmp=$1
  cat >"$tmp/colors" <<'SH'
#!/bin/sh
BOLD=""
CYAN=""
RESET=""
SH
  chmod +x "$tmp/colors"
}

make_stub_exit_label() {
  tmp=$1
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
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

test_wallet_menu_prompts_install_when_missing() {
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  make_stub_exit_label "$tmp"
  make_status_stub "$tmp" "missing"
  make_boolean_stub "$tmp/is-bitcoin-installed" 1
  make_boolean_stub "$tmp/is-service-installed" 1
  make_boolean_stub "$tmp/is-bitcoin-running" 1

  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/install/bitcoin/wallet-menu"
  _assert_success
  _assert_file_contains "$tmp/log" "Bitcoin: missing"
  _assert_file_contains "$tmp/log" "Install or Upgrade Bitcoin%install-bitcoin"
}

test_wallet_menu_shows_wallet_controls_when_installed() {
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  make_stub_exit_label "$tmp"
  make_status_stub "$tmp" "ready"
  make_boolean_stub "$tmp/is-bitcoin-installed" 0
  make_boolean_stub "$tmp/is-service-installed" 1
  make_boolean_stub "$tmp/is-bitcoin-running" 0

  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/install/bitcoin/wallet-menu"
  _assert_success
  _assert_file_contains "$tmp/log" "Check Wallet Balance"
  _assert_file_contains "$tmp/log" "Get New Receive Address"
  _assert_file_contains "$tmp/log" "Send Bitcoin"
  _assert_file_contains "$tmp/log" "Uninstall Bitcoin%uninstall-bitcoin"
}

test_wallet_menu_shows_stop_when_running() {
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  make_stub_exit_label "$tmp"
  make_status_stub "$tmp" "ready"
  make_boolean_stub "$tmp/is-bitcoin-installed" 0
  make_boolean_stub "$tmp/is-service-installed" 1
  make_boolean_stub "$tmp/is-bitcoin-running" 0

  _run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/install/bitcoin/wallet-menu"
  _assert_success
  _assert_file_contains "$tmp/log" "Stop bitcoind%bitcoin-cli stop"
}

_run_test_case "wallet-menu prompts for install when missing" test_wallet_menu_prompts_install_when_missing
_run_test_case "wallet-menu shows wallet controls when installed" test_wallet_menu_shows_wallet_controls_when_installed
_run_test_case "wallet-menu shows stop when daemon running" test_wallet_menu_shows_stop_when_running

test_shows_help() {
  _run_cmd "$ROOT_DIR/spells/install/bitcoin/wallet-menu" --help
  _assert_success
  _assert_output_contains "Usage: wallet-menu"
}

_run_test_case "wallet-menu --help shows usage" test_shows_help

_finish_tests
