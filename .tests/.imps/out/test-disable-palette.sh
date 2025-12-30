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
  run_cmd sh -c "RESET=1; . '$ROOT_DIR/spells/.imps/out/disable-palette'; printf '%s' \"\$RESET\""
  assert_success
  # RESET should be empty after disable-palette
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="RESET should be empty but got: $OUTPUT"; return 1; }
}

test_disable_palette_clears_theme_colors() {
  run_cmd sh -c "THEME_HIGHLIGHT=1; . '$ROOT_DIR/spells/.imps/out/disable-palette'; printf '%s' \"\$THEME_HIGHLIGHT\""
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="THEME_HIGHLIGHT should be empty but got: $OUTPUT"; return 1; }
}

test_disable_palette_clears_mud_colors() {
  run_cmd sh -c "MUD_LOCATION=1; . '$ROOT_DIR/spells/.imps/out/disable-palette'; printf '%s' \"\$MUD_LOCATION\""
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="MUD_LOCATION should be empty but got: $OUTPUT"; return 1; }
}

test_disable_palette_sets_flag() {
  skip-if-compiled || return $?
  run_cmd sh -c "WIZARDRY_COLORS_AVAILABLE=1; . '$ROOT_DIR/spells/.imps/out/disable-palette'; printf '%s' \"\$WIZARDRY_COLORS_AVAILABLE\""
  assert_success
  [ "$OUTPUT" = "0" ] || { TEST_FAILURE_REASON="WIZARDRY_COLORS_AVAILABLE should be 0 but got: $OUTPUT"; return 1; }
}

test_disable_palette_multiple_colors_empty() {
  skip-if-compiled || return $?
  # Check that multiple color variables are all set to empty
  run_cmd sh -c "RED=1 GREEN=1 BLUE=1 CYAN=1; . '$ROOT_DIR/spells/.imps/out/disable-palette'; printf '%s|%s|%s|%s' \"\$RED\" \"\$GREEN\" \"\$BLUE\" \"\$CYAN\""
  assert_success
  [ "$OUTPUT" = "|||" ] || { TEST_FAILURE_REASON="Color variables should all be empty but got: $OUTPUT"; return 1; }
}

run_test_case "disable-palette clears RESET color" test_disable_palette_clears_colors
run_test_case "disable-palette clears theme colors" test_disable_palette_clears_theme_colors
run_test_case "disable-palette clears MUD colors" test_disable_palette_clears_mud_colors
run_test_case "disable-palette sets WIZARDRY_COLORS_AVAILABLE=0" test_disable_palette_sets_flag
run_test_case "disable-palette clears multiple colors" test_disable_palette_multiple_colors_empty

finish_tests
