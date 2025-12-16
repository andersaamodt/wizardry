#!/bin/sh
# Tests for the 'disable-palette' imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"


test_disable_palette_clears_colors() {
  # Source colors first, then source disable-palette and run the function, check that variables are empty
  _run_cmd sh -c ". '$ROOT_DIR/spells/cantrips/colors'; . '$ROOT_DIR/spells/.imps/out/disable-palette'; _disable_palette; printf '%s' \"\$RESET\""
  _assert_success
  # RESET should be empty after disable-palette
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="RESET should be empty but got: $OUTPUT"; return 1; }
}

test_disable_palette_clears_theme_colors() {
  _run_cmd sh -c ". '$ROOT_DIR/spells/cantrips/colors'; . '$ROOT_DIR/spells/.imps/out/disable-palette'; _disable_palette; printf '%s' \"\$THEME_HIGHLIGHT\""
  _assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="THEME_HIGHLIGHT should be empty but got: $OUTPUT"; return 1; }
}

test_disable_palette_clears_mud_colors() {
  _run_cmd sh -c ". '$ROOT_DIR/spells/cantrips/colors'; . '$ROOT_DIR/spells/.imps/out/disable-palette'; _disable_palette; printf '%s' \"\$MUD_LOCATION\""
  _assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="MUD_LOCATION should be empty but got: $OUTPUT"; return 1; }
}

test_disable_palette_sets_flag() {
  skip-if-compiled || return $?
  _run_cmd sh -c ". '$ROOT_DIR/spells/cantrips/colors'; . '$ROOT_DIR/spells/.imps/out/disable-palette'; _disable_palette; printf '%s' \"\$WIZARDRY_COLORS_AVAILABLE\""
  _assert_success
  [ "$OUTPUT" = "0" ] || { TEST_FAILURE_REASON="WIZARDRY_COLORS_AVAILABLE should be 0 but got: $OUTPUT"; return 1; }
}

test_disable_palette_multiple_colors_empty() {
  skip-if-compiled || return $?
  # Check that multiple color variables are all set to empty
  _run_cmd sh -c ". '$ROOT_DIR/spells/cantrips/colors'; . '$ROOT_DIR/spells/.imps/out/disable-palette'; _disable_palette; printf '%s|%s|%s|%s' \"\$RED\" \"\$GREEN\" \"\$BLUE\" \"\$CYAN\""
  _assert_success
  [ "$OUTPUT" = "|||" ] || { TEST_FAILURE_REASON="Color variables should all be empty but got: $OUTPUT"; return 1; }
}

_run_test_case "disable-palette clears RESET color" test_disable_palette_clears_colors
_run_test_case "disable-palette clears theme colors" test_disable_palette_clears_theme_colors
_run_test_case "disable-palette clears MUD colors" test_disable_palette_clears_mud_colors
_run_test_case "disable-palette sets WIZARDRY_COLORS_AVAILABLE=0" test_disable_palette_sets_flag
_run_test_case "disable-palette clears multiple colors" test_disable_palette_multiple_colors_empty

_finish_tests
