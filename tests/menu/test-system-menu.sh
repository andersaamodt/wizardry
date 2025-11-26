#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - system-menu requires the menu dependency
# - system-menu forwards system actions to the menu

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

test_system_menu_checks_requirements() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" REQUIRE_LOG="$tmp/req" "$ROOT_DIR/spells/menu/system-menu"
  assert_success && assert_path_exists "$tmp/req"
}

test_system_menu_includes_test_utilities() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/system-menu"
  assert_success
  args=$(cat "$tmp/log")
  case "$args" in
    *"System Menu:"*"Manage services%services-menu"*"Update wizardry%update-wizardry"*"Test all wizardry spells%$ROOT_DIR/spells/system/test-magic"*"Force restart%sudo shutdown -r now"*"Exit%kill -2"* ) : ;;
    *) TEST_FAILURE_REASON="expected system actions missing"; return 1 ;;
  esac
}

run_test_case "system-menu requires menu dependency" test_system_menu_checks_requirements
run_test_case "system-menu passes system actions to menu" test_system_menu_includes_test_utilities
spell_has_shebang() {
  head -1 "$ROOT_DIR/spells/menu/system-menu" | grep -q "^#!"
}

run_test_case "menu/system-menu has shebang" spell_has_shebang
finish_tests
