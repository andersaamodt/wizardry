#!/bin/sh
# Tests for uninstall-clipboard-helper spell

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_uninstall_clipboard_helper_is_executable() {
  [ -x "$ROOT_DIR/spells/install/core/uninstall-clipboard-helper" ]
}

test_uninstall_clipboard_helper_has_content() {
  [ -s "$ROOT_DIR/spells/install/core/uninstall-clipboard-helper" ]
}

test_uninstall_clipboard_helper_reports_no_helper_when_none_installed() {
  fixture=$(_make_fixture)
  _provide_basic_tools "$fixture"

  # Run with no clipboard helpers installed
  PATH="$fixture/bin" HOME="$fixture/home" _run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" \
    "$ROOT_DIR/spells/install/core/uninstall-clipboard-helper"

  _assert_success || return 1
  _assert_output_contains "No removable clipboard helper installed" || return 1
}

shows_help() {
  _run_spell spells/install/core/uninstall-clipboard-helper --help
  true
}

_run_test_case "uninstall-clipboard-helper is executable" test_uninstall_clipboard_helper_is_executable
_run_test_case "uninstall-clipboard-helper has content" test_uninstall_clipboard_helper_has_content
_run_test_case "uninstall-clipboard-helper reports no helper when none installed" test_uninstall_clipboard_helper_reports_no_helper_when_none_installed
_run_test_case "uninstall-clipboard-helper shows help" shows_help
_finish_tests
