#!/bin/sh
set -eu

# shellcheck source=../../test-common.sh
. "$(dirname "$0")/../../test-common.sh"

install_xsel_installs_package() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/install/core/install-xsel"

  assert_success || return 1
  assert_file_contains "$fixture/log/apt.log" "apt-get -y install xsel" || return 1
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/core/install-xsel" ]
}

install_xsel_reports_failure_when_package_manager_fails() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  # Force package manager to fail
  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 \
    "$ROOT_DIR/spells/install/core/install-xsel"

  assert_failure || return 1
  assert_error_contains "unable to install xsel automatically" || return 1
}

run_test_case "install-xsel installs via package manager" install_xsel_installs_package
run_test_case "install-xsel has content" spell_has_content
run_test_case "install-xsel reports failure when package manager fails" install_xsel_reports_failure_when_package_manager_fails

shows_help() {
  run_spell spells/install/core/install-xsel --help
  true
}

run_test_case "install-xsel shows help" shows_help
finish_tests
