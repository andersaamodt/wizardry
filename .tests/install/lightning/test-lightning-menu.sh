#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/lightning/lightning-menu" ]
}
run_test_case "install/lightning/lightning-menu is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/lightning/lightning-menu" ]
}
run_test_case "install/lightning/lightning-menu has content" spell_has_content

shows_usage_help() {
  run_spell spells/install/lightning/lightning-menu --help
  assert_success || return 1
  assert_output_contains "Usage: lightning-menu"
}
run_test_case "lightning-menu shows usage help" shows_usage_help

contains_uninstall_entry() {
  assert_file_contains "$ROOT_DIR/spells/install/lightning/lightning-menu" "Uninstall Lightning"
}
run_test_case "lightning-menu includes uninstall entry" contains_uninstall_entry

shows_full_menu_when_installed() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/lightning-menu.XXXXXX")
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
  cat >"$tmpdir/bin/lightning-status" <<'STUB'
#!/bin/sh
printf 'ready'
STUB
  cat >"$tmpdir/bin/lightning-cli" <<'STUB'
#!/bin/sh
exit 0
STUB
  cat >"$tmpdir/bin/is-service-installed" <<'STUB'
#!/bin/sh
exit 0
STUB
  cat >"$tmpdir/bin/is-service-running" <<'STUB'
#!/bin/sh
if [ "${SERVICE_RUNNING:-0}" -eq 1 ]; then exit 0; else exit 1; fi
STUB
  cat >"$tmpdir/bin/systemctl" <<'STUB'
#!/bin/sh
exit 0
STUB
  cat >"$tmpdir/bin/menu" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" >"${MENU_LOG:?}"
kill -TERM "$PPID"
STUB
  chmod +x "$tmpdir/bin"/*

  MENU_LOG="$log" SERVICE_RUNNING=1 PATH="$tmpdir/bin:$PATH" run_spell spells/install/lightning/lightning-menu

  assert_file_contains "$log" "Lightning Info%lightning-cli getinfo"
  assert_file_contains "$log" "Lightning Wallet Menu%lightning-wallet-menu"
  assert_file_contains "$log" "Stop Lightning%sudo systemctl stop lightningd"
  assert_file_contains "$log" "Uninstall Lightning%uninstall-lightning"
}
run_test_case "lightning-menu shows actions when installed" shows_full_menu_when_installed

offers_install_when_missing() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/lightning-menu-missing.XXXXXX")
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
  cat >"$tmpdir/bin/lightning-status" <<'STUB'
#!/bin/sh
printf 'missing'
STUB
  cat >"$tmpdir/bin/is-service-installed" <<'STUB'
#!/bin/sh
exit 1
STUB
  cat >"$tmpdir/bin/is-service-running" <<'STUB'
#!/bin/sh
exit 1
STUB
  cat >"$tmpdir/bin/sudo" <<'STUB'
#!/bin/sh
exec "$@"
STUB
  cat >"$tmpdir/bin/menu" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" >"${MENU_LOG:?}"
kill -TERM "$PPID"
STUB
  chmod +x "$tmpdir/bin"/*

  MENU_LOG="$log" PATH="$tmpdir/bin:$PATH" run_spell spells/install/lightning/lightning-menu
  assert_file_contains "$log" "Install Lightning%install-lightning"
}
run_test_case "lightning-menu offers install option when missing" offers_install_when_missing

finish_tests
