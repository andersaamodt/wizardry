#!/bin/sh
set -eu

# Locate test helpers
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/node/node-menu" ]
}

_run_test_case "install/node/node-menu is executable" spell_is_executable

make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SHI'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -TERM "$PPID" 2>/dev/null || exit 0
SHI
  chmod +x "$tmp/menu"
}

menu_shows_install_when_node_missing() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"
  cat >"$tmp/exit-label" <<'SHI'
#!/bin/sh
printf '%s' "Exit"
SHI
  chmod +x "$tmp/exit-label"

  cat >"$tmp/node-status" <<'SHI'
#!/bin/sh
echo "not installed"
SHI
  chmod +x "$tmp/node-status"

  MENU_LOG="$tmp/menu.log"

  _run_cmd env PATH="$WIZARDRY_SYSTEM_PATH:$WIZARDRY_IMPS_PATH:$tmp:$ROOT_DIR/spells/cantrips" MENU_LOG="$MENU_LOG" \
    "$ROOT_DIR/spells/.arcana/node/node-menu"

  _assert_success || return 1
  _assert_path_exists "$MENU_LOG" || return 1
  content=$(cat "$MENU_LOG")
  case "$content" in
    *"Install Node.js%install-node"* ) : ;;
    *) TEST_FAILURE_REASON="install option missing"; return 1 ;;
  esac
  case "$content" in
    *'Exit%kill -TERM $PPID'* ) : ;;
    *) TEST_FAILURE_REASON="exit option missing"; return 1 ;;
  esac
}

_run_test_case "node-menu shows install flow when Node.js is absent" menu_shows_install_when_node_missing

menu_places_uninstall_before_exit_when_installed() {
  skip-if-compiled || return $?
  tmp=$(_make_tempdir)
  make_stub_menu "$tmp"

  cat >"$tmp/exit-label" <<'SHI'
#!/bin/sh
printf '%s' "Exit"
SHI
  chmod +x "$tmp/exit-label"

  cat >"$tmp/node-status" <<'SHI'
#!/bin/sh
echo "installed"
SHI
  chmod +x "$tmp/node-status"

  # Stub node tools and service helpers
  cat >"$tmp/node" <<'SHI'
#!/bin/sh
case "$1" in
  --version)
    echo "v20.0.0"
    ;;
  -e)
    echo "ok"
    ;;
  *)
    :
    ;;
 esac
SHI
  chmod +x "$tmp/node"

  cat >"$tmp/npm" <<'SHI'
#!/bin/sh
case "$1" in
  --version)
    echo "10.0.0"
    ;;
  list)
    echo "npm list"
    ;;
  *)
    :
    ;;
 esac
SHI
  chmod +x "$tmp/npm"

  cat >"$tmp/is-service-installed" <<'SHI'
#!/bin/sh
exit 0
SHI
  chmod +x "$tmp/is-service-installed"

  cat >"$tmp/is-service-running" <<'SHI'
#!/bin/sh
exit 0
SHI
  chmod +x "$tmp/is-service-running"

  MENU_LOG="$tmp/menu.log"
  _run_cmd env PATH="$WIZARDRY_SYSTEM_PATH:$WIZARDRY_IMPS_PATH:$tmp:$ROOT_DIR/spells/cantrips" MENU_LOG="$MENU_LOG" \
    "$ROOT_DIR/spells/.arcana/node/node-menu"

  _assert_success || return 1
  _assert_path_exists "$MENU_LOG" || return 1

  # Skip the title; inspect menu entries
  entries=$(tail -n +2 "$MENU_LOG")
  last_line=$(printf '%s\n' "$entries" | tail -n 1)
  second_last=$(printf '%s\n' "$entries" | tail -n 2 | head -n 1)

  case "$second_last" in
    "Uninstall Node.js%uninstall-node") : ;;
    *) TEST_FAILURE_REASON="uninstall option should be second to last"; return 1 ;;
  esac

  case "$last_line" in
    *'%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="exit option should be last"; return 1 ;;
  esac

  case "$entries" in
    *"Show Node version%node --version"* ) : ;; 
    *) TEST_FAILURE_REASON="version entry missing"; return 1 ;;
  esac

  case "$entries" in
    *"Restart Node service%sudo systemctl restart node"* ) : ;; 
    *) TEST_FAILURE_REASON="service restart entry missing"; return 1 ;;
  esac
}

_run_test_case "node-menu orders uninstall before exit and surfaces node helpers" menu_places_uninstall_before_exit_when_installed

_finish_tests
