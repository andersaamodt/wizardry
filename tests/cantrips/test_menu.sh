#!/bin/sh
# Behavioral cases (derived from --help):
# - menu validates MENU_ESCAPE_STATUS
# - menu checks that required helpers exist before trying to draw
# - menu fails fast when no controlling terminal is available

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

menu_rejects_invalid_escape_status() {
  run_cmd env MENU_ESCAPE_STATUS=abc "$ROOT_DIR/spells/cantrips/menu"
  assert_failure || return 1
  assert_error_contains "MENU_ESCAPE_STATUS must be a non-negative integer" || return 1
}

menu_rejects_out_of_range_escape_status() {
  run_cmd env MENU_ESCAPE_STATUS=300 "$ROOT_DIR/spells/cantrips/menu"
  assert_failure || return 1
  assert_error_contains "MENU_ESCAPE_STATUS must be between 0 and 255" || return 1
}

menu_requires_all_helpers() {
  PATH="$ROOT_DIR/spells/.imps:/bin:/usr/bin" run_cmd env PATH="$ROOT_DIR/spells/.imps:/bin:/usr/bin" "$ROOT_DIR/spells/cantrips/menu" "Menu" "Item%echo hi"
  assert_failure || return 1
  assert_error_contains "The menu spell needs 'fathom-cursor' to place the menu." || return 1
}

menu_reports_missing_tty() {
  stub_dir=$(make_tempdir)
  for helper in fathom-cursor fathom-terminal move-cursor await-keypress cursor-blink stty; do
    printf '#!/bin/sh\nexit 0\n' >"$stub_dir/$helper"
    chmod +x "$stub_dir/$helper"
  done

  PATH="$ROOT_DIR/spells/.imps:$stub_dir:/bin:/usr/bin" run_cmd env PATH="$ROOT_DIR/spells/.imps:$stub_dir:/bin:/usr/bin" AWAIT_KEYPRESS_DEVICE="$stub_dir/fake-tty" \
    "$ROOT_DIR/spells/cantrips/menu" "Menu" "Item%echo hi"
  assert_failure || return 1
  assert_error_contains "menu: unable to access controlling terminal" || return 1
}

run_test_case "menu rejects non-numeric escape status" menu_rejects_invalid_escape_status
run_test_case "menu rejects escape status above 255" menu_rejects_out_of_range_escape_status
run_test_case "menu requires helper spells" menu_requires_all_helpers
run_test_case "menu reports missing controlling terminal" menu_reports_missing_tty
finish_tests
