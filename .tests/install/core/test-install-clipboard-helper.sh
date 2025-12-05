#!/bin/sh
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/core/install-clipboard-helper" ]
}

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/core/install-clipboard-helper" ]
}

shows_help() {
  run_spell "spells/install/core/install-clipboard-helper" --help
  assert_success || return 1
  if printf '%s%s' "$OUTPUT" "$ERROR" | grep -q "Usage: install-clipboard-helper"; then
    return 0
  else
    TEST_FAILURE_REASON="expected Usage output"
    return 1
  fi
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
run_test_case "install-clipboard-helper shows help" shows_help
run_test_case "install-clipboard-helper --detect-preferred returns valid helper" detect_preferred_returns_value
run_test_case "install-clipboard-helper --label returns label with helper name" label_returns_value

finish_tests
