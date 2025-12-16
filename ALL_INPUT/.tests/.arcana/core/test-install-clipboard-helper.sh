#!/bin/sh
set -eu

# shellcheck source=../../spells/.imps/test/test-bootstrap
# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/core/install-clipboard-helper" ]
}

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/core/install-clipboard-helper" ]
}

shows_help() {
  _run_spell "spells/.arcana/core/install-clipboard-helper" --help
  _assert_success || return 1
  if printf '%s%s' "$OUTPUT" "$ERROR" | grep -q "Usage: install-clipboard-helper"; then
    return 0
  else
    TEST_FAILURE_REASON="expected Usage output"
    return 1
  fi
}

detect_preferred_returns_value() {
  _run_spell "spells/.arcana/core/install-clipboard-helper" --detect-preferred
  _assert_success || return 1
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
  _run_spell "spells/.arcana/core/install-clipboard-helper" --label
  _assert_success || return 1
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

_run_test_case "install-clipboard-helper has content" spell_has_content
_run_test_case "install-clipboard-helper is executable" spell_is_executable
_run_test_case "install-clipboard-helper shows help" shows_help
_run_test_case "install-clipboard-helper --detect-preferred returns valid helper" detect_preferred_returns_value
_run_test_case "install-clipboard-helper --label returns label with helper name" label_returns_value

_finish_tests
