#!/bin/sh
set -eu

# shellcheck source=../../spells/.imps/test/test-bootstrap
. "$(dirname "$0")/../../spells/.imps/test/test-bootstrap"

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/core/install-clipboard-helper" ]
}

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/core/install-clipboard-helper" ]
}

detect_preferred_returns_value() {
  run_spell "spells/install/core/install-clipboard-helper" --detect-preferred
  assert_success || return 1
  # Should return one of the known helpers
  case "$OUTPUT" in
    pbcopy|xsel|xclip|wl-copy)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="unexpected output: $OUTPUT"
      return 1
      ;;
  esac
}

label_returns_value() {
  run_spell "spells/install/core/install-clipboard-helper" --label
  assert_success || return 1
  # Should contain one of the known helpers in the output
  case "$OUTPUT" in
    *pbcopy*|*xsel*|*xclip*|*wl-copy*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="unexpected output: $OUTPUT"
      return 1
      ;;
  esac
}

run_test_case "install-clipboard-helper has content" spell_has_content
run_test_case "install-clipboard-helper is executable" spell_is_executable
run_test_case "install-clipboard-helper --detect-preferred returns valid helper" detect_preferred_returns_value
run_test_case "install-clipboard-helper --label returns label with helper name" label_returns_value

finish_tests
