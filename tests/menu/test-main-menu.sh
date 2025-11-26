#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - main-menu requires menu dependency before running
# - main-menu invokes menu with expected options and honors escape status

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 113
SH
  chmod +x "$tmp/menu"
}

make_stub_require() {
  tmp=$1
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s %s\n' "$1" "$2" >>"$REQUIRE_LOG"
exit 0
SH
  chmod +x "$tmp/require-command"
}

test_main_menu_checks_dependency() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" REQUIRE_LOG="$tmp/req" "$ROOT_DIR/spells/menu/main-menu"
  assert_success && assert_path_exists "$tmp/req"
}

test_main_menu_passes_expected_entries() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/main-menu"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"Main Menu:"*"MUD menu%mud"*"Cast a Spell%cast"*"Spellbook%spellbook"*"Install Free Software%install-menu"*"Manage System%system-menu"*"Exit%kill -2"* ) : ;;
    *) TEST_FAILURE_REASON="menu entries missing"; return 1 ;;
  esac
}

run_test_case "main-menu requires menu dependency" test_main_menu_checks_dependency
run_test_case "main-menu forwards menu entries" test_main_menu_passes_expected_entries
spell_has_shebang() {
  head -1 "$ROOT_DIR/spells/menu/main-menu" | grep -q "^#!"
}

run_test_case "menu/main-menu has shebang" spell_has_shebang
finish_tests
