#!/bin/sh
# Behavioral cases (derived from --help):
# - menu validates MENU_ESCAPE_STATUS
# - menu checks that required helpers exist before trying to draw
# - menu fails fast when no controlling terminal is available

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

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

# Test MENU_START_SELECTION - Issue #198
# When MENU_START_SELECTION=2, pressing enter should select the second item
menu_respects_start_selection() {
  stub_dir=$(make_tempdir)
  
  # Create a fake TTY for testing
  touch "$stub_dir/fake-tty"
  chmod 600 "$stub_dir/fake-tty"
  
  # Create stubs for all required helper commands
  cat >"$stub_dir/fathom-cursor" <<'STUB'
#!/bin/sh
case $1 in
  -y) printf '1\n' ;;
  -x) printf '1\n' ;;
  *) printf '1 1\n' ;;
esac
STUB
  chmod +x "$stub_dir/fathom-cursor"
  
  cat >"$stub_dir/fathom-terminal" <<'STUB'
#!/bin/sh
case $1 in
  -w) printf '80\n' ;;
  -h) printf '24\n' ;;
  *) printf '80 24\n' ;;
esac
STUB
  chmod +x "$stub_dir/fathom-terminal"
  
  cat >"$stub_dir/move-cursor" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/move-cursor"
  
  # await-keypress returns "enter" immediately
  cat >"$stub_dir/await-keypress" <<'STUB'
#!/bin/sh
printf 'enter\n'
STUB
  chmod +x "$stub_dir/await-keypress"
  
  cat >"$stub_dir/cursor-blink" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/cursor-blink"
  
  cat >"$stub_dir/stty" <<'STUB'
#!/bin/sh
case $1 in
  -g) printf 'saved-state\n' ;;
  *) exit 0 ;;
esac
STUB
  chmod +x "$stub_dir/stty"
  
  # Run menu with MENU_START_SELECTION=2 and press enter immediately
  # Should execute the second item's command (printf second)
  PATH="$ROOT_DIR/spells/.imps:$stub_dir:/bin:/usr/bin" run_cmd env \
    PATH="$ROOT_DIR/spells/.imps:$stub_dir:/bin:/usr/bin" \
    MENU_START_SELECTION=2 \
    AWAIT_KEYPRESS_DEVICE="$stub_dir/fake-tty" \
    "$ROOT_DIR/spells/cantrips/menu" "Test:" \
    "First%printf first" \
    "Second%printf second" \
    "Third%printf third"
  
  assert_success || return 1
  # The second item should have been selected since MENU_START_SELECTION=2
  case "$OUTPUT" in
    *second*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="expected 'second' in output but got: $OUTPUT"
      return 1
      ;;
  esac
}

run_test_case "menu respects MENU_START_SELECTION (Issue #198)" menu_respects_start_selection

finish_tests
