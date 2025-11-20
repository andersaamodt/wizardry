#!/bin/sh
# Behavioral cases (derived from --help):
# - menu validates MENU_ESCAPE_STATUS

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

menu_rejects_invalid_escape_status() {
  run_cmd env MENU_ESCAPE_STATUS=abc "$ROOT_DIR/spells/cantrips/menu"
  assert_failure || return 1
  assert_error_contains "MENU_ESCAPE_STATUS must be a non-negative integer" || return 1
}

run_test_case "menu rejects non-numeric escape status" menu_rejects_invalid_escape_status
finish_tests
