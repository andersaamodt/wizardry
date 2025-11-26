#!/bin/sh
set -eu

# shellcheck source=../../test-common.sh
. "$(dirname "$0")/../../test-common.sh"

install_git_installs_package() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/install/core/install-git"

  assert_success || return 1
  assert_file_contains "$fixture/log/apt.log" "apt-get -y install git" || return 1
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/core/install-git" ]
}

run_test_case "install-git installs via package manager" install_git_installs_package
run_test_case "install-git has content" spell_has_content

finish_tests
