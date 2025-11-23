#!/bin/sh
set -eu

# shellcheck source=../../test_common.sh
. "$(dirname "$0")/../../test_common.sh"

install_core_installs_all_missing() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/install/core/install-core"

  assert_success || return 1
  for cmd in await-keypress menu cursor-blink fathom-cursor fathom-terminal move-cursor; do
    assert_path_exists "$fixture/home/.local/bin/$cmd" || return 1
  done
  installs=$(grep -c "apt-get -y install" "$fixture/log/apt.log" || true)
  [ "$installs" -ge 1 ] || { TEST_FAILURE_REASON="no system installs attempted"; return 1; }
}

run_test_case "install-core installs all dependencies" install_core_installs_all_missing

finish_tests
