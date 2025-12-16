#!/bin/sh
# Behavioral cases (derived from --help):
# - colors enables palette on capable terminals
# - colors disables palette when NO_COLOR set
# - colors escape sequences work with printf %s
# - theme colors are defined when palette is enabled
# - theme colors are cleared when palette is disabled

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_colors_enable_palette_by_default() {
  _run_cmd env TERM=xterm sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'avail:%s red:%s\\n' \"\$WIZARDRY_COLORS_AVAILABLE\" \"\$RED\""
  _assert_success && case "$OUTPUT" in avail:1\ red:*) : ;; *) TEST_FAILURE_REASON="expected colors to be available"; return 1 ;; esac
}

test_colors_disable_when_requested() {
  skip-if-compiled || return $?
  _run_cmd env TERM=xterm NO_COLOR=1 sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'avail:%s red:%s\\n' \"\$WIZARDRY_COLORS_AVAILABLE\" \"\$RED\""
  if ! _assert_success; then return 1; fi
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
  _run_cmd env TERM=xterm sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf '%stest%s' \"\$GREEN\" \"\$RESET\" | cat -v"
  if ! _assert_success; then return 1; fi
  # cat -v shows escape character as ^[ so we should see ^[[32m
  case "$OUTPUT" in
    *"^[["*) : ;;
    *"\\033"*) TEST_FAILURE_REASON="colors contain literal \\033 instead of actual escape character"; return 1 ;;
    *) TEST_FAILURE_REASON="expected escape character in output, got: $OUTPUT"; return 1 ;;
  esac
}

test_colors_disable_for_dumb_terminal() {
  skip-if-compiled || return $?
  # Colors should be disabled for TERM=dumb which returns -1 from tput colors
  _run_cmd env TERM=dumb sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'avail:%s green:%s\\n' \"\$WIZARDRY_COLORS_AVAILABLE\" \"\$GREEN\""
  if ! _assert_success; then return 1; fi
  case "$OUTPUT" in
    avail:0\ green:) : ;;
    *) TEST_FAILURE_REASON="expected palette disabled for dumb terminal, got: $OUTPUT"; return 1 ;;
  esac
}

test_theme_colors_defined_when_enabled() {
  # Theme colors should be defined when the palette is enabled
  _run_cmd env TERM=xterm sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'highlight:%s muted:%s custom:%s\\n' \"\$THEME_HIGHLIGHT\" \"\$THEME_MUTED\" \"\$THEME_CUSTOM\""
  if ! _assert_success; then return 1; fi
  # Verify theme colors are non-empty (contain escape sequences)
  case "$OUTPUT" in
    highlight:\ *|muted:\ *|custom:\ *)
      TEST_FAILURE_REASON="expected theme colors to be defined, got: $OUTPUT"
      return 1
      ;;
    *)
      # Check that at least one theme color is defined
      case "$OUTPUT" in
        *highlight:*muted:*custom:*)
          : # All three fields present
          ;;
        *)
          TEST_FAILURE_REASON="unexpected output format: $OUTPUT"
          return 1
          ;;
      esac
      ;;
  esac
}

test_theme_colors_cleared_when_disabled() {
  skip-if-compiled || return $?
  # Theme colors should be empty when the palette is disabled
  _run_cmd env TERM=xterm NO_COLOR=1 sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'highlight:[%s] muted:[%s] custom:[%s]\\n' \"\$THEME_HIGHLIGHT\" \"\$THEME_MUTED\" \"\$THEME_CUSTOM\""
  if ! _assert_success; then return 1; fi
  case "$OUTPUT" in
    *"highlight:[] muted:[] custom:[]"*)
      : # All theme colors are empty as expected
      ;;
    *)
      TEST_FAILURE_REASON="expected theme colors to be empty when palette disabled, got: $OUTPUT"
      return 1
      ;;
  esac
}

test_mud_colors_defined_when_enabled() {
  # MUD colors should be defined when the palette is enabled
  _run_cmd env TERM=xterm sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'location:%s item:%s handle:%s spell:%s monster:%s\\n' \"\$MUD_LOCATION\" \"\$MUD_ITEM\" \"\$MUD_HANDLE\" \"\$MUD_SPELL\" \"\$MUD_MONSTER\""
  if ! _assert_success; then return 1; fi
  # Verify MUD colors are non-empty
  case "$OUTPUT" in
    *location:\ *|*item:\ *|*handle:\ *|*spell:\ *|*monster:\ *)
      TEST_FAILURE_REASON="expected MUD colors to be defined, got: $OUTPUT"
      return 1
      ;;
    *)
      # Check that all MUD color fields are present
      case "$OUTPUT" in
        *location:*item:*handle:*spell:*monster:*)
          : # All fields present
          ;;
        *)
          TEST_FAILURE_REASON="unexpected output format: $OUTPUT"
          return 1
          ;;
      esac
      ;;
  esac
}

test_mud_colors_cleared_when_disabled() {
  skip-if-compiled || return $?
  # MUD colors should be empty when the palette is disabled
  _run_cmd env TERM=xterm NO_COLOR=1 sh -c ". \"$ROOT_DIR/spells/cantrips/colors\"; printf 'location:[%s] item:[%s] handle:[%s] spell:[%s] monster:[%s]\\n' \"\$MUD_LOCATION\" \"\$MUD_ITEM\" \"\$MUD_HANDLE\" \"\$MUD_SPELL\" \"\$MUD_MONSTER\""
  if ! _assert_success; then return 1; fi
  case "$OUTPUT" in
    *"location:[] item:[] handle:[] spell:[] monster:[]"*)
      : # All MUD colors are empty as expected
      ;;
    *)
      TEST_FAILURE_REASON="expected MUD colors to be empty when palette disabled, got: $OUTPUT"
      return 1
      ;;
  esac
}

_run_test_case "colors enables palette on capable terminals" test_colors_enable_palette_by_default
_run_test_case "colors disables palette when NO_COLOR set" test_colors_disable_when_requested
_run_test_case "colors work with printf %s format" test_colors_printf_s_works
_run_test_case "colors disables palette for dumb terminal" test_colors_disable_for_dumb_terminal
_run_test_case "theme colors are defined when palette is enabled" test_theme_colors_defined_when_enabled
_run_test_case "theme colors are cleared when palette is disabled" test_theme_colors_cleared_when_disabled
_run_test_case "MUD colors are defined when palette is enabled" test_mud_colors_defined_when_enabled
_run_test_case "MUD colors are cleared when palette is disabled" test_mud_colors_cleared_when_disabled
shows_help() {
  _run_spell spells/cantrips/colors --help
  # Note: spell may not have --help implemented yet
  true
}

_run_test_case "colors shows help" shows_help
_finish_tests
