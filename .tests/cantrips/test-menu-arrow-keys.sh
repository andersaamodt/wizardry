#!/bin/sh
# Test menu arrow key navigation with realistic input simulation

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that menu responds to arrow up key
menu_arrow_up_navigation() {
  tmpdir=$(make_tempdir)
  
  # Create sequence stub: start at item 3, press up twice, then enter
  # This should select item 1 (wrapping from 3 -> 2 -> 1)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Link to sequence stub (not the default stub)
  ln -s "$ROOT_DIR/spells/.imps/test/stub-await-keypress-sequence" "$stub_dir/await-keypress"
  
  # Link to other stubs (terminal I/O)
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty; do
    ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
  done
  
  # Set up key sequence and index file
  export AWAIT_KEYPRESS_SEQUENCE="up up enter"
  export AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/key-index"
  
  # Run menu starting at item 3, navigate up to item 1
  PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" run_cmd \
    env AWAIT_KEYPRESS_SEQUENCE="up up enter" AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/key-index" \
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
  
  # Create sequence stub: start at item 1, press down once, then enter
  # This should select item 2
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Link to sequence stub
  ln -s "$ROOT_DIR/spells/.imps/test/stub-await-keypress-sequence" "$stub_dir/await-keypress"
  
  # Link to other stubs
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty; do
    ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
  done
  
  # Set up key sequence
  export AWAIT_KEYPRESS_SEQUENCE="down enter"
  export AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/key-index"
  
  # Run menu starting at item 1, navigate down to item 2
  PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" run_cmd \
    env AWAIT_KEYPRESS_SEQUENCE="down enter" AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/key-index" \
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

# Test wrapping: arrow up from first item goes to last item
menu_arrow_wrapping() {
  tmpdir=$(make_tempdir)
  
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  ln -s "$ROOT_DIR/spells/.imps/test/stub-await-keypress-sequence" "$stub_dir/await-keypress"
  
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty; do
    ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
  done
  
  # Press up from item 1 should wrap to item 3 (last)
  export AWAIT_KEYPRESS_SEQUENCE="up enter"
  export AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/key-index"
  
  PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" run_cmd \
    env AWAIT_KEYPRESS_SEQUENCE="up enter" AWAIT_KEYPRESS_INDEX_FILE="$tmpdir/key-index" \
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

finish_tests
