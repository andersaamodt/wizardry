#!/bin/sh
set -eu

# Locate test helpers
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/web-wizardry/web-wizardry-status" ]
}

run_test_case "web-wizardry-status is executable" spell_is_executable

renders_usage_information() {
  skip-if-compiled || return $?
  run_cmd "$ROOT_DIR/spells/.arcana/web-wizardry/web-wizardry-status" --help

  assert_success || return 1
  assert_output_contains "Usage: web-wizardry-status" || return 1
  assert_output_contains "installation status of web wizardry" || return 1
}

run_test_case "web-wizardry-status prints usage with --help" renders_usage_information

reports_not_installed_without_components() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  # Link only essential utilities, NO web components
  link_tools "$tmp" sh cat printf test env basename dirname pwd tr

  run_cmd env PATH="$tmp:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips" \
    "$ROOT_DIR/spells/.arcana/web-wizardry/web-wizardry-status"

  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

run_test_case "web-wizardry-status reports not installed when components absent" reports_not_installed_without_components

finish_tests
