#!/bin/sh
# Behavioral cases (derived from --help):
# - colors enables palette on capable terminals
# - colors disables palette when NO_COLOR set

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

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

run_test_case "colors enables palette on capable terminals" test_colors_enable_palette_by_default
run_test_case "colors disables palette when NO_COLOR set" test_colors_disable_when_requested
finish_tests
