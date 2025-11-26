#!/bin/sh
set -eu

# shellcheck source=../../test-common.sh
. "$(dirname "$0")/../../test-common.sh"

install_stty_installs_package() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/install/core/install-stty"

  assert_success || return 1
  assert_file_contains "$fixture/log/apt.log" "apt-get -y install coreutils" || return 1
}

run_test_case "install-stty installs via package manager" install_stty_installs_package

finish_tests
