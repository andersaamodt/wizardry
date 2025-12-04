#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/lightning/lightning-wallet-menu" ]
}
run_test_case "install/lightning/lightning-wallet-menu is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/lightning/lightning-wallet-menu" ]
}
run_test_case "install/lightning/lightning-wallet-menu has content" spell_has_content

shows_usage_help() {
  run_spell spells/install/lightning/lightning-wallet-menu --help
  assert_success || return 1
  assert_output_contains "Usage: lightning-wallet-menu"
}
run_test_case "lightning-wallet-menu shows usage help" shows_usage_help

contains_wallet_actions() {
  assert_file_contains "$ROOT_DIR/spells/install/lightning/lightning-wallet-menu" "lightning-cli listfunds"
  assert_file_contains "$ROOT_DIR/spells/install/lightning/lightning-wallet-menu" "lightning-cli newaddr"
}
run_test_case "lightning-wallet-menu lists wallet actions" contains_wallet_actions

renders_menu_entries() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/lightning-wallet-menu.XXXXXX")
  mkdir -p "$tmpdir/bin"
  log="$tmpdir/menu.log"

  cat >"$tmpdir/bin/colors" <<'STUB'
#!/bin/sh
BOLD=""
CYAN=""
STUB
  cat >"$tmpdir/bin/exit-label" <<'STUB'
#!/bin/sh
printf 'Exit'
STUB
  cat >"$tmpdir/bin/menu" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" >"${MENU_LOG:?}"
exit 0
STUB
  chmod +x "$tmpdir/bin"/*

  timeout 5 sh -c 'MENU_LOG="$0" PATH="$1" "$2" </dev/null' "$log" "$tmpdir/bin:$PATH" "$ROOT_DIR/spells/install/lightning/lightning-wallet-menu"

  assert_file_contains "$log" "Lightning Wallet"
  assert_file_contains "$log" "List Funds%lightning-cli listfunds"
  assert_file_contains "$log" "Generate New Address%lightning-cli newaddr"
  assert_file_contains "$log" "Create Invoice%sh -c 'amt="
  assert_file_contains "$log" "lightning-cli invoice"
  assert_file_contains "$log" "Pay Invoice%sh -c 'printf \"Invoice: \"; read -r inv; lightning-cli pay"
  assert_file_contains "$log" "Exit%kill -TERM"
}
run_test_case "lightning-wallet-menu renders wallet actions" renders_menu_entries

finish_tests
