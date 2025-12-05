#!/bin/sh
# Tests for uninstall-clipboard-helper spell

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_uninstall_clipboard_helper_is_executable() {
  [ -x "$ROOT_DIR/spells/install/core/uninstall-clipboard-helper" ]
}

test_uninstall_clipboard_helper_has_content() {
  [ -s "$ROOT_DIR/spells/install/core/uninstall-clipboard-helper" ]
}

test_uninstall_clipboard_helper_reports_no_helper_when_none_installed() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"

  # Run with no clipboard helpers installed
  PATH="$fixture/bin" HOME="$fixture/home" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" \
    "$ROOT_DIR/spells/install/core/uninstall-clipboard-helper"

  assert_success || return 1
  assert_output_contains "No removable clipboard helper installed" || return 1
}

shows_help() {
  run_spell spells/install/core/uninstall-clipboard-helper --help
  true
}

run_test_case "uninstall-clipboard-helper is executable" test_uninstall_clipboard_helper_is_executable
run_test_case "uninstall-clipboard-helper has content" test_uninstall_clipboard_helper_has_content
run_test_case "uninstall-clipboard-helper reports no helper when none installed" test_uninstall_clipboard_helper_reports_no_helper_when_none_installed
run_test_case "uninstall-clipboard-helper shows help" shows_help
finish_tests
