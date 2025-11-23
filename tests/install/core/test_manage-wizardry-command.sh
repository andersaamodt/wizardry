#!/bin/sh
set -eu

# shellcheck source=../../test_common.sh
. "$(dirname "$0")/../../test_common.sh"
# shellcheck source=./core_test_helpers.sh
. "$(dirname "$0")/core_test_helpers.sh"

manage_wizardry_installs_shim() {
  fixture=$(make_fixture)
  PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/manage-wizardry-command" shim-test spells/cantrips/await-keypress

  assert_success || return 1
  assert_path_exists "$fixture/home/.local/bin/shim-test" || return 1
}

manage_wizardry_handles_existing_command() {
  fixture=$(make_fixture)
  write_command_stub "$fixture/bin" shim-test

  PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/manage-wizardry-command" shim-test spells/cantrips/await-keypress

  assert_success || return 1
  [ ! -e "$fixture/home/.local/bin/shim-test" ] || { TEST_FAILURE_REASON="shim should not be created"; return 1; }
}

manage_wizardry_uninstalls_shim() {
  fixture=$(make_fixture)
  ln -s "$ROOT_DIR/spells/cantrips/await-keypress" "$fixture/home/.local/bin/shim-test"

  PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/manage-wizardry-command" --uninstall shim-test spells/cantrips/await-keypress

  assert_success || return 1
  [ ! -e "$fixture/home/.local/bin/shim-test" ] || { TEST_FAILURE_REASON="shim should be removed"; return 1; }
}

manage_wizardry_requires_source() {
  fixture=$(make_fixture)
  PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/manage-wizardry-command" shim-missing spells/does-not-exist

  assert_failure || return 1
  assert_error_contains "does not exist" || return 1
}

run_test_case "manage-wizardry-command installs shim" manage_wizardry_installs_shim
run_test_case "manage-wizardry-command returns when command exists" manage_wizardry_handles_existing_command
run_test_case "manage-wizardry-command removes shim" manage_wizardry_uninstalls_shim
run_test_case "manage-wizardry-command requires source" manage_wizardry_requires_source

finish_tests
