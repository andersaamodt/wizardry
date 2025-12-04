#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/tor/tor-menu" ]
}

run_test_case "install/tor/tor-menu is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/tor/tor-menu" ]
}

run_test_case "install/tor/tor-menu has content" spell_has_content

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/install/tor/tor-menu" --help
  assert_success
  assert_output_contains "Usage: tor-menu"
}

run_test_case "tor-menu --help shows usage" test_shows_help

records_menu_items_when_installed() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/tor-menu.XXXXXX")
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
  cat >"$tmpdir/bin/tor-status" <<'STUB'
#!/bin/sh
printf 'running'
STUB
  cat >"$tmpdir/bin/is-installed" <<'STUB'
#!/bin/sh
if [ "${TOR_INSTALLED:-1}" -eq 1 ]; then exit 0; else exit 1; fi
STUB
  cat >"$tmpdir/bin/is-service-installed" <<'STUB'
#!/bin/sh
if [ "${TOR_SERVICE_INSTALLED:-1}" -eq 1 ]; then exit 0; else exit 1; fi
STUB
  cat >"$tmpdir/bin/is-service-running" <<'STUB'
#!/bin/sh
if [ "${TOR_SERVICE_RUNNING:-1}" -eq 1 ]; then exit 0; else exit 1; fi
STUB
  cat >"$tmpdir/bin/tor-bridge-status" <<'STUB'
#!/bin/sh
if [ "${TOR_BRIDGE_ENABLED:-0}" -eq 1 ]; then exit 0; else exit 1; fi
STUB
  cat >"$tmpdir/bin/systemctl" <<'STUB'
#!/bin/sh
exit 0
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

  MENU_LOG="$log" TOR_INSTALLED=1 TOR_SERVICE_INSTALLED=1 TOR_SERVICE_RUNNING=1 \
    PATH="$tmpdir/bin:$PATH" run_spell spells/install/tor/tor-menu

  assert_file_contains "$log" "Repair Permissions%sudo repair-tor-permissions"
  assert_file_contains "$log" "Stop Tor Service%sudo systemctl stop tor"
  assert_file_contains "$log" "Uninstall Tor%uninstall-tor"
  assert_file_contains "$log" "Enable Bridge Mode"
}
run_test_case "tor-menu lists management entries when installed" records_menu_items_when_installed

offers_install_option_when_missing() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/tor-menu-missing.XXXXXX")
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
  cat >"$tmpdir/bin/tor-status" <<'STUB'
#!/bin/sh
printf 'missing'
STUB
  cat >"$tmpdir/bin/is-installed" <<'STUB'
#!/bin/sh
exit 1
STUB
  cat >"$tmpdir/bin/is-installed" <<'STUB'
#!/bin/sh
exit 1
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
  cat >"$tmpdir/bin/tor-bridge-status" <<'STUB'
#!/bin/sh
exit 1
STUB
  cat >"$tmpdir/bin/menu" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" >"${MENU_LOG:?}"
kill -TERM "$PPID"
STUB
  chmod +x "$tmpdir/bin"/*

  MENU_LOG="$log" PATH="$tmpdir/bin:$PATH" run_spell spells/install/tor/tor-menu
  assert_file_contains "$log" "Install Tor (wizard)%install-tor"
}
run_test_case "tor-menu offers install when tor missing" offers_install_option_when_missing

finish_tests
