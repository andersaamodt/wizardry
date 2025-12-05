#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/core/core-status" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/core/core-status" ]
}

run_test_case "install/core/core-status is executable" spell_is_executable
run_test_case "install/core/core-status has content" spell_has_content

shows_help() {
  run_spell spells/install/core/core-status --help
  true
}

run_test_case "core-status shows help" shows_help

# Test that status output is one of the expected values
status_output_is_valid() {
  run_spell spells/install/core/core-status
  case "$OUTPUT" in
    installed|"not installed"|"partial install")
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="unexpected output: $OUTPUT"
      return 1
      ;;
  esac
}

run_test_case "core-status outputs valid status" status_output_is_valid

# Test that status does not show internal markers like __clipboard_helper__
status_no_internal_markers() {
  run_spell spells/install/core/core-status
  case "$OUTPUT" in
    *__clipboard_helper__*)
      TEST_FAILURE_REASON="output contains internal marker __clipboard_helper__"
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

run_test_case "core-status hides internal markers" status_no_internal_markers

finish_tests
