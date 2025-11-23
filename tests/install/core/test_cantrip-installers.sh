#!/bin/sh
set -eu

# shellcheck source=../../test_common.sh
. "$(dirname "$0")/../../test_common.sh"

install_cantrip_creates_shim() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/install-await-keypress"

  assert_success || return 1
  assert_path_exists "$fixture/home/.local/bin/await-keypress" || return 1
}

install_cantrip_skips_existing_command() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  write_command_stub "$fixture/bin" await-keypress

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/install-await-keypress"

  assert_success || return 1
  [ ! -e "$fixture/home/.local/bin/await-keypress" ] || { TEST_FAILURE_REASON="should not install when command exists"; return 1; }
}

uninstall_cantrip_removes_managed_shim() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  ln -s "$ROOT_DIR/spells/cantrips/await-keypress" "$fixture/home/.local/bin/await-keypress"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/uninstall-await-keypress"

  assert_success || return 1
  [ ! -e "$fixture/home/.local/bin/await-keypress" ] || { TEST_FAILURE_REASON="shim should be removed"; return 1; }
}

uninstall_cantrip_preserves_foreign_command() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  printf '#!/bin/sh\nexit 0\n' >"$fixture/home/.local/bin/await-keypress"
  chmod +x "$fixture/home/.local/bin/await-keypress"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/uninstall-await-keypress"

  assert_success || return 1
  assert_path_exists "$fixture/home/.local/bin/await-keypress" || return 1
}

run_test_case "install-await-keypress installs wizardry command" install_cantrip_creates_shim
run_test_case "install-await-keypress skips when command exists" install_cantrip_skips_existing_command
run_test_case "uninstall-await-keypress removes wizardry shim" uninstall_cantrip_removes_managed_shim
run_test_case "uninstall-await-keypress leaves external command" uninstall_cantrip_preserves_foreign_command

finish_tests
