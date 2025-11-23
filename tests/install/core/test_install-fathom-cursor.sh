#!/bin/sh
set -eu

# shellcheck source=../../test_common.sh
. "$(dirname "$0")/../../test_common.sh"

install_creates_shim() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/install-fathom-cursor"

  assert_success || return 1
  assert_path_exists "$fixture/home/.local/bin/fathom-cursor" || return 1
}

install_skips_existing_command() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  write_command_stub "$fixture/bin" fathom-cursor

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/install-fathom-cursor"

  assert_success || return 1
  [ ! -e "$fixture/home/.local/bin/fathom-cursor" ] || { TEST_FAILURE_REASON="should not install when command exists"; return 1; }
}

run_test_case "install-fathom-cursor installs shim" install_creates_shim
run_test_case "install-fathom-cursor skips existing command" install_skips_existing_command

finish_tests
