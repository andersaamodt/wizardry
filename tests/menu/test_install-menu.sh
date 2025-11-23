#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - install-menu fails when no installable entries exist
# - install-menu builds menu entries from provided directories and status helpers

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

make_stub_menu_env() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit "${MENU_STATUS:-113}"
SH
  chmod +x "$tmp/menu"
}

make_stub_require() {
  tmp=$1
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/require-command"
}

test_install_menu_prefers_install_root_commands() {
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"

  install_root="$tmp/install"
  mkdir -p "$install_root/alpha" "$install_root/beta" "$install_root/gamma"

  cat >"$install_root/alpha/alpha-status" <<'SH'
#!/bin/sh
echo configured
SH
  chmod +x "$install_root/alpha/alpha-status"

  cat >"$install_root/alpha/alpha" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$install_root/alpha/alpha"

  cat >"$install_root/beta-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/beta-status"

  cat >"$install_root/beta-menu" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$install_root/beta-menu"

  MENU_LOG="$tmp/log"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="alpha beta gamma" MENU_LOG="$MENU_LOG" "$ROOT_DIR/spells/menu/install-menu"

  assert_success && assert_path_exists "$MENU_LOG" && \
    assert_output_contains "Install Menu:"

  menu_args=$(cat "$MENU_LOG")

  case "$menu_args" in
    *"alpha - configured%$install_root/alpha/alpha"* ) : ;;
    *) TEST_FAILURE_REASON="alpha entry missing nested command"; return 1 ;;
  esac

  case "$menu_args" in
    *"beta - ready%launch_submenu $install_root/beta-menu"* ) : ;;
    *) TEST_FAILURE_REASON="beta entry missing submenu command"; return 1 ;;
  esac

  case "$menu_args" in
    *"gamma - coming soon%printf \"This entry is not ready yet.\\n\""* ) : ;;
    *) TEST_FAILURE_REASON="gamma entry missing fallback message"; return 1 ;;
  esac
}

test_install_menu_errors_when_empty() {
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_DIRS=" " MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/install-menu"
  assert_failure && assert_error_contains "no installable spells"
}

test_install_menu_builds_entries_with_status() {
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/alpha-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$tmp/alpha-status"
  cat >"$tmp/alpha-menu" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/alpha-menu"
  MENU_LOG="$tmp/log"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_DIRS="alpha beta" MENU_LOG="$MENU_LOG" "$ROOT_DIR/spells/menu/install-menu"
  assert_success && assert_path_exists "$MENU_LOG" && \
    assert_output_contains "Install Menu:"
  menu_args=$(cat "$MENU_LOG")
  case "$menu_args" in
    *"alpha - ready%launch_submenu alpha-menu"* ) : ;; 
    *) TEST_FAILURE_REASON="menu entries missing status"; return 1 ;;
  esac
}

run_test_case "install-menu fails when empty" test_install_menu_errors_when_empty
run_test_case "install-menu builds entries from directories" test_install_menu_builds_entries_with_status
run_test_case "install-menu prefers spells in the install root" test_install_menu_prefers_install_root_commands
finish_tests
