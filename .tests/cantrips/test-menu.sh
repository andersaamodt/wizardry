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
  helper_path="$ROOT_DIR/spells/.imps/sys:/bin:/usr/bin"
  run_cmd env PATH="$helper_path" "$ROOT_DIR/spells/cantrips/menu" "Menu" "Item%echo hi"
  assert_failure || return 1
  assert_error_contains "The menu spell needs 'fathom-cursor' to place the menu." || return 1
}

menu_reports_missing_tty() {
  # This test verifies menu fails when /dev/tty is not accessible
  # We override AWAIT_KEYPRESS_DEVICE to point to a non-existent file
  tmpdir=$(make_tempdir)
  
  # Use reusable stub imps
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Link to stub imps (terminal I/O stubs)
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty await-keypress; do
    ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
  done

  # Set AWAIT_KEYPRESS_DEVICE to a non-existent file to trigger the TTY check failure
  run_cmd env \
    PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" \
    AWAIT_KEYPRESS_DEVICE="$tmpdir/nonexistent-tty" \
    "$ROOT_DIR/spells/cantrips/menu" "Menu" "Item%echo hi"
  assert_failure || return 1
  assert_error_contains "menu: unable to access controlling terminal" || return 1
}

menu_shows_help() {
  run_cmd "$ROOT_DIR/spells/cantrips/menu" --help
  assert_success || return 1
}

run_test_case "menu shows help" menu_shows_help
run_test_case "menu requires helper spells" menu_requires_all_helpers
run_test_case "menu reports missing controlling terminal" menu_reports_missing_tty

# Skip if /dev/tty is not functional (e.g., in CI environment)
# Check if stty can actually read from /dev/tty, not just if file exists
if [ "${WIZARDRY_TEST_IN_POCKET-0}" = "1" ]; then
  test_skip "menu respects --start-selection (Issue #198)" "requires functional /dev/tty"
elif ! stty -g </dev/tty >/dev/null 2>&1; then
  test_skip "menu respects --start-selection (Issue #198)" "requires functional /dev/tty"
else
  # Test --start-selection argument - Issue #198
  # When --start-selection 2 is passed, pressing enter should select the second item
  menu_respects_start_selection() {
    tmpdir=$(make_tempdir)
    
    # Use real wizardry spells with stub imps for terminal I/O AND interactive input
    # This tests the REAL menu spell with stubbed await-keypress
    stub_dir="$tmpdir/stubs"
    mkdir -p "$stub_dir"
    
    # Link to stub imps (terminal I/O + interactive input stubs)
    for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty await-keypress; do
      ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
    done
    
    # Run REAL menu with stub await-keypress that returns "enter"
    # This allows menu to select the current item and exit cleanly
    PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" run_cmd \
      "$ROOT_DIR/spells/cantrips/menu" --start-selection 2 "Test:" \
      "First%printf first" \
      "Second%printf second" \
      "Third%printf third"
    
    assert_success || return 1
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
  run_test_case "menu respects --start-selection (Issue #198)" menu_respects_start_selection
fi

# Skip if /dev/tty is not functional (e.g., in CI environment)
# Check if stty can actually read from /dev/tty, not just if file exists
if [ "${WIZARDRY_TEST_IN_POCKET-0}" = "1" ]; then
  test_skip "menu highlight strips ANSI codes from labels" "requires functional /dev/tty"
elif ! stty -g </dev/tty >/dev/null 2>&1; then
  test_skip "menu highlight strips ANSI codes from labels" "requires functional /dev/tty"
else
  # Test that highlighted items strip ANSI codes from labels
  # This ensures the highlight color (CYAN) overrides embedded colors (like YELLOW)
  menu_highlight_strips_ansi_codes() {
    tmpdir=$(make_tempdir)
    
    # Create a fake TTY for testing
    
    # Create a buffer file with enter key
    
    # Use reusable stub imps via symlinks
    stub_dir="$tmpdir/stubs"
    mkdir -p "$stub_dir"
    
    # Link to stub imps (terminal I/O + interactive input stubs)
    for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty await-keypress; do
      ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
    done
    
    # Create an ANSI-colored label with ESC[33m (yellow) embedded
    # The output should NOT contain the yellow ANSI code (ESC[33m) for the highlighted item
    # but SHOULD contain the highlight color (ESC[36m = cyan)
    yellow_code=$(printf '\033[33m')
    reset_code=$(printf '\033[0m')
    
    PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" run_cmd env \
      TERM=xterm \
      "$ROOT_DIR/spells/cantrips/menu" "Test:" \
      "${yellow_code}ColoredItem${reset_code}%printf selected"
    
    assert_success || return 1
    
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
  run_test_case "menu highlight strips ANSI codes from labels" menu_highlight_strips_ansi_codes
fi

# Skip if /dev/tty is not functional (e.g., in CI environment)
# Check if stty can actually read from /dev/tty, not just if file exists
if [ "${WIZARDRY_TEST_IN_POCKET-0}" = "1" ]; then
  test_skip "menu restores cursor on exit" "requires functional /dev/tty"
elif ! stty -g </dev/tty >/dev/null 2>&1; then
  test_skip "menu restores cursor on exit" "requires functional /dev/tty"
else
  # Test that cursor is restored when exiting menu
  # This verifies the fix for the cursor disappearance issue
  menu_restores_cursor_on_exit() {
    tmpdir=$(make_tempdir)
    
    # Create a fake TTY for testing
    
    # Create a buffer file with enter key
    
    # Use reusable stub imps via symlinks
    stub_dir="$tmpdir/stubs"
    mkdir -p "$stub_dir"
    
    # Link to stub imps (terminal I/O stubs only)
    for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty await-keypress; do
      ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
    done
    
    # Run menu and verify cursor is restored (turned back on)
    PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" run_cmd env \
      PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" \
      TERM=xterm \
      "$ROOT_DIR/spells/cantrips/menu" "Test:" "Item%printf selected"
    
    assert_success || return 1
    
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
  run_test_case "menu restores cursor on exit" menu_restores_cursor_on_exit
fi

# Skip arrow key tests if /dev/tty is not functional (e.g., in CI environment)
if [ "${WIZARDRY_TEST_IN_POCKET-0}" = "1" ]; then
  test_skip "menu arrow key navigation" "requires functional /dev/tty"
elif ! stty -g </dev/tty >/dev/null 2>&1; then
  test_skip "menu arrow key navigation" "requires functional /dev/tty"
else
  # Test that menu responds to arrow up key
  menu_arrow_up_navigation() {
    tmpdir=$(make_tempdir)
    
    stub_dir="$tmpdir/stubs"
    mkdir -p "$stub_dir"
    
    # Create a custom await-keypress that returns our sequence
    cat > "$stub_dir/await-keypress" <<'STUB_EOF'
#!/bin/sh
# Custom await-keypress for testing - returns up, up, enter sequence
index_file="${AWAIT_KEYPRESS_INDEX_FILE:-/tmp/menu-test-index}"
if [ ! -f "$index_file" ]; then
  printf '0' > "$index_file"
fi
index=$(cat "$index_file")

# Sequence: up, up, enter (from item 3 -> 2 -> 1)
case "$index" in
  0) printf 'up\n'; printf '1' > "$index_file" ;;
  1) printf 'up\n'; printf '2' > "$index_file" ;;
  *) printf 'enter\n' ;;
esac
STUB_EOF
    chmod +x "$stub_dir/await-keypress"
    
    # Link other stubs
    for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty; do
      ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
    done
    
    export AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/key-index"
    
    # Run menu starting at item 3, navigate up twice to item 1
    PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" run_cmd \
      env AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/key-index" \
      "$ROOT_DIR/spells/cantrips/menu" --start-selection 3 "Navigation Test:" \
      "First Item%printf first" \
      "Second Item%printf second" \
      "Third Item%printf third"
    
    assert_success || return 1
    
    # After pressing up twice from item 3, we should be at item 1
    case "$OUTPUT" in
      *first*)
        return 0
        ;;
      *)
        TEST_FAILURE_REASON="expected 'first' in output but got: $OUTPUT"
        return 1
        ;;
    esac
  }

  # Test that menu responds to arrow down key
  menu_arrow_down_navigation() {
    tmpdir=$(make_tempdir)
    
    stub_dir="$tmpdir/stubs"
    mkdir -p "$stub_dir"
    
    # Custom await-keypress: down, enter
    cat > "$stub_dir/await-keypress" <<'STUB_EOF'
#!/bin/sh
index_file="${AWAIT_KEYPRESS_INDEX_FILE:-/tmp/menu-test-index}"
if [ ! -f "$index_file" ]; then
  printf '0' > "$index_file"
fi
index=$(cat "$index_file")

case "$index" in
  0) printf 'down\n'; printf '1' > "$index_file" ;;
  *) printf 'enter\n' ;;
esac
STUB_EOF
    chmod +x "$stub_dir/await-keypress"
    
    for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty; do
      ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
    done
    
    export AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/key-index"
    
    PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" run_cmd \
      env AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/key-index" \
      "$ROOT_DIR/spells/cantrips/menu" --start-selection 1 "Navigation Test:" \
      "First Item%printf first" \
      "Second Item%printf second" \
      "Third Item%printf third"
    
    assert_success || return 1
    
    # After pressing down once from item 1, we should be at item 2
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

  # Test wrapping: arrow up from first item wraps to last
  menu_arrow_wrapping() {
    tmpdir=$(make_tempdir)
    
    stub_dir="$tmpdir/stubs"
    mkdir -p "$stub_dir"
    
    # Custom await-keypress: up (from item 1 should wrap to item 3), enter
    cat > "$stub_dir/await-keypress" <<'STUB_EOF'
#!/bin/sh
index_file="${AWAIT_KEYPRESS_INDEX_FILE:-/tmp/menu-test-index}"
if [ ! -f "$index_file" ]; then
  printf '0' > "$index_file"
fi
index=$(cat "$index_file")

case "$index" in
  0) printf 'up\n'; printf '1' > "$index_file" ;;
  *) printf 'enter\n' ;;
esac
STUB_EOF
    chmod +x "$stub_dir/await-keypress"
    
    for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty; do
      ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
    done
    
    export AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/key-index"
    
    PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" run_cmd \
      env AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/key-index" \
      "$ROOT_DIR/spells/cantrips/menu" --start-selection 1 "Navigation Test:" \
      "First Item%printf first" \
      "Second Item%printf second" \
      "Third Item%printf third"
    
    assert_success || return 1
    
    case "$OUTPUT" in
      *third*)
        return 0
        ;;
      *)
        TEST_FAILURE_REASON="expected 'third' in output (wrapping) but got: $OUTPUT"
        return 1
        ;;
    esac
  }

  run_test_case "menu responds to arrow up keys" menu_arrow_up_navigation
  run_test_case "menu responds to arrow down keys" menu_arrow_down_navigation
  run_test_case "menu wraps around when navigating with arrows" menu_arrow_wrapping
fi

finish_tests
