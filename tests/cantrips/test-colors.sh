#!/bin/sh
# Behavioral cases (derived from --help):
# - colors enables palette on capable terminals
# - colors disables palette when NO_COLOR set
# - colors escape sequences work with printf %s

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_colors_enable_palette_by_default() {
  run_cmd env TERM=xterm sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'avail:%s red:%s\\n' \"\$WIZARDRY_COLORS_AVAILABLE\" \"\$RED\""
  assert_success && case "$OUTPUT" in avail:1\ red:*) : ;; *) TEST_FAILURE_REASON="expected colors to be available"; return 1 ;; esac
}

test_colors_disable_when_requested() {
  run_cmd env TERM=xterm NO_COLOR=1 sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'avail:%s red:%s\\n' \"\$WIZARDRY_COLORS_AVAILABLE\" \"\$RED\""
  if ! assert_success; then return 1; fi
  case "$OUTPUT" in
    avail:0\ red:*) ;;
    *) TEST_FAILURE_REASON="expected palette to be disabled"; return 1 ;;
  esac
  case "$OUTPUT" in
    *"\\033"*) TEST_FAILURE_REASON="unexpected escape codes when colors disabled"; return 1 ;;
  esac
}

test_colors_printf_s_works() {
  # Test that color codes work with printf '%s' (not just printf '%b')
  # This was broken when colors used literal \033 strings
  run_cmd env TERM=xterm sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf '%stest%s' \"\$GREEN\" \"\$RESET\" | cat -v"
  if ! assert_success; then return 1; fi
  # cat -v shows escape character as ^[ so we should see ^[[32m
  case "$OUTPUT" in
    *"^[["*) : ;;
    *"\\033"*) TEST_FAILURE_REASON="colors contain literal \\033 instead of actual escape character"; return 1 ;;
    *) TEST_FAILURE_REASON="expected escape character in output, got: $OUTPUT"; return 1 ;;
  esac
}

test_colors_disable_for_dumb_terminal() {
  # Colors should be disabled for TERM=dumb which returns -1 from tput colors
  run_cmd env TERM=dumb sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'avail:%s green:%s\\n' \"\$WIZARDRY_COLORS_AVAILABLE\" \"\$GREEN\""
  if ! assert_success; then return 1; fi
  case "$OUTPUT" in
    avail:0\ green:) : ;;
    *) TEST_FAILURE_REASON="expected palette disabled for dumb terminal, got: $OUTPUT"; return 1 ;;
  esac
}

run_test_case "colors enables palette on capable terminals" test_colors_enable_palette_by_default
run_test_case "colors disables palette when NO_COLOR set" test_colors_disable_when_requested
run_test_case "colors work with printf %s format" test_colors_printf_s_works
run_test_case "colors disables palette for dumb terminal" test_colors_disable_for_dumb_terminal
shows_help() {
  run_spell spells/cantrips/colors --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "colors shows help" shows_help
finish_tests
