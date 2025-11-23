#!/bin/sh
set -eu

# shellcheck source=../../test_common.sh
. "$(dirname "$0")/../../test_common.sh"

install_tput_installs_package() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/install/core/install-tput"

  assert_success || return 1
  assert_file_contains "$fixture/log/apt.log" "apt-get -y install ncurses-bin" || return 1
}

run_test_case "install-tput installs via package manager" install_tput_installs_package

finish_tests
