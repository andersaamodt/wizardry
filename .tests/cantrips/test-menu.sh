#!/bin/sh
# COMPILED_UNSUPPORTED: requires interactive input
# Behavioral cases (derived from --help):
# - menu checks that required helpers exist before trying to draw
# - menu fails fast when no controlling terminal is available

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

menu_requires_all_helpers() {
  PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" _run_cmd env PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" "$ROOT_DIR/spells/cantrips/menu" "Menu" "Item%echo hi"
  _assert_failure || return 1
  _assert_error_contains "The menu spell needs 'fathom-cursor' to place the menu." || return 1
}

menu_reports_missing_tty() {
  stub_dir=$(_make_tempdir)
  for helper in fathom-cursor fathom-terminal move-cursor await-keypress cursor-blink stty; do
    printf '#!/bin/sh\nexit 0\n' >"$stub_dir/$helper"
    chmod +x "$stub_dir/$helper"
  done

  PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$stub_dir:/bin:/usr/bin" _run_cmd env PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$stub_dir:/bin:/usr/bin" AWAIT_KEYPRESS_DEVICE="$stub_dir/fake-tty" \
    "$ROOT_DIR/spells/cantrips/menu" "Menu" "Item%echo hi"
  _assert_failure || return 1
  _assert_error_contains "menu: unable to access controlling terminal" || return 1
}

_run_test_case "menu requires helper spells" menu_requires_all_helpers
_run_test_case "menu reports missing controlling terminal" menu_reports_missing_tty

# Test --start-selection argument - Issue #198
# When --start-selection 2 is passed, pressing enter should select the second item
menu_respects_start_selection() {
  tmpdir=$(_make_tempdir)
  
  # Create a fake TTY file with newline byte (will be read by dd when buffer is empty)
  printf '\n' > "$tmpdir/fake-tty"
  chmod 600 "$tmpdir/fake-tty"
  
  # Create buffer file with "enter" key code (byte 10 = newline)
  # await-keypress reads buffer first, then falls back to tty device
  printf '10' > "$tmpdir/input-buffer"
  
  # Use real wizardry spells, but create symlinks to stub imps for terminal I/O
  # This tests the REAL menu spell with REAL await-keypress
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Link to stub imps (terminal I/O stubs only)
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty; do
    ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
  done
  
  # Run REAL menu with REAL await-keypress, using stub imps only for terminal I/O
  PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" _run_cmd env \
    PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" \
    AWAIT_KEYPRESS_DEVICE="$tmpdir/fake-tty" \
    AWAIT_KEYPRESS_SKIP_STTY=1 \
    AWAIT_KEYPRESS_BUFFER_FILE="$tmpdir/input-buffer" \
    "$ROOT_DIR/spells/cantrips/menu" --start-selection 2 "Test:" \
    "First%printf first" \
    "Second%printf second" \
    "Third%printf third" < "$tmpdir/fake-tty"
  
  _assert_success || return 1
  # The second item should have been selected since --start-selection 2
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

_run_test_case "menu respects --start-selection (Issue #198)" menu_respects_start_selection

# Test that highlighted items strip ANSI codes from labels
# This ensures the highlight color (CYAN) overrides embedded colors (like YELLOW)
menu_highlight_strips_ansi_codes() {
  tmpdir=$(_make_tempdir)
  
  # Create a fake TTY for testing
  touch "$tmpdir/fake-tty"
  chmod 600 "$tmpdir/fake-tty"
  
  # Create a buffer file with enter key
  printf '10' > "$tmpdir/input-buffer"
  
  # Use reusable stub imps via symlinks
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Link to stub imps (terminal I/O stubs only)
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty; do
    ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
  done
  
  # Create an ANSI-colored label with ESC[33m (yellow) embedded
  # The output should NOT contain the yellow ANSI code (ESC[33m) for the highlighted item
  # but SHOULD contain the highlight color (ESC[36m = cyan)
  yellow_code=$(printf '\033[33m')
  reset_code=$(printf '\033[0m')
  
  PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" _run_cmd env \
    PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" \
    AWAIT_KEYPRESS_DEVICE="$tmpdir/fake-tty" \
    AWAIT_KEYPRESS_SKIP_STTY=1 \
    AWAIT_KEYPRESS_BUFFER_FILE="$tmpdir/input-buffer" \
    TERM=xterm \
    "$ROOT_DIR/spells/cantrips/menu" "Test:" \
    "${yellow_code}ColoredItem${reset_code}%printf selected"
  
  _assert_success || return 1
  
  # Verify the command executed (item was selectable)
  case "$OUTPUT" in
    *selected*)
      : # good
      ;;
    *)
      TEST_FAILURE_REASON="expected 'selected' in output"
      return 1
      ;;
  esac
  
  # The highlighted row should NOT contain the yellow escape code
  # because the menu should strip it when highlighting
  case "$OUTPUT" in
    *"${yellow_code}"*)
      TEST_FAILURE_REASON="output should not contain yellow ANSI code in highlighted row"
      return 1
      ;;
  esac
  
  return 0
}

_run_test_case "menu highlight strips ANSI codes from labels" menu_highlight_strips_ansi_codes

# Test that cursor is restored when exiting menu
# This verifies the fix for the cursor disappearance issue
menu_restores_cursor_on_exit() {
  tmpdir=$(_make_tempdir)
  
  # Create a fake TTY for testing
  touch "$tmpdir/fake-tty"
  chmod 600 "$tmpdir/fake-tty"
  
  # Create a buffer file with enter key
  printf '10' > "$tmpdir/input-buffer"
  
  # Use reusable stub imps via symlinks
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Link to stub imps (terminal I/O stubs only)
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty; do
    ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
  done
  
  # Run menu and verify cursor is restored (turned back on)
  PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" _run_cmd env \
    PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" \
    AWAIT_KEYPRESS_DEVICE="$tmpdir/fake-tty" \
    AWAIT_KEYPRESS_SKIP_STTY=1 \
    AWAIT_KEYPRESS_BUFFER_FILE="$tmpdir/input-buffer" \
    TERM=xterm \
    "$ROOT_DIR/spells/cantrips/menu" "Test:" "Item%printf selected"
  
  _assert_success || return 1
  
  # Verify the menu output contains the cursor-off escape code (menu hides cursor)
  cursor_off=$(printf '\033[?25l')
  case "$OUTPUT" in
    *"$cursor_off"*)
      : # good - cursor was hidden
      ;;
    *)
      TEST_FAILURE_REASON="expected cursor-off escape code in output"
      return 1
      ;;
  esac
  
  # Verify the menu output contains the cursor-on escape code (menu restores cursor)
  cursor_on=$(printf '\033[?25h')
  case "$OUTPUT" in
    *"$cursor_on"*)
      return 0 # cursor was restored
      ;;
    *)
      TEST_FAILURE_REASON="expected cursor-on escape code in output (cursor not restored)"
      return 1
      ;;
  esac
}

_run_test_case "menu restores cursor on exit" menu_restores_cursor_on_exit

_finish_tests
