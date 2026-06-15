#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/mobile-debugging-menu" --help
  assert_success
  assert_output_contains "Usage: mobile-debugging-menu"
}

menu_lists_platform_tools_toggle() {
  tmpdir=$(make_tempdir)

  cat >"$tmpdir/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${MENU_LOG:?}"
exit 130
SH
  chmod +x "$tmpdir/menu"

  MENU_LOG="$tmpdir/menu.log" run_cmd env PATH="$WIZARDRY_IMPS_PATH:$tmpdir:/bin:/usr/bin" MENU_BIN="$tmpdir/menu" MENU_LOG="$tmpdir/menu.log" XDG_DATA_HOME="$tmpdir/data" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/mobile-debugging-menu"

  assert_success || return 1
  assert_file_contains "$tmpdir/menu.log" "Android platform tools (adb)"
  assert_file_contains "$tmpdir/menu.log" "Maestro CLI"
  assert_file_contains "$tmpdir/menu.log" "firewalled-adb help"
  assert_file_contains "$tmpdir/menu.log" "firewalled-maestro help"
}

run_test_case "mobile-debugging-menu shows help" shows_help
run_test_case "mobile-debugging-menu lists platform tools toggle" menu_lists_platform_tools_toggle

finish_tests
