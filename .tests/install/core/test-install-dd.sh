#!/bin/sh
set -eu

# shellcheck source=../../spells/.imps/test/test-bootstrap
. "$(dirname "$0")/../../spells/.imps/test/test-bootstrap"

install_dd_installs_package() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/install/core/install-dd"

  assert_success || return 1
  assert_file_contains "$fixture/log/apt.log" "apt-get -y install coreutils" || return 1
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/core/install-dd" ]
}

install_dd_reports_failure_when_package_manager_fails() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  # Force package manager to fail
  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 \
    "$ROOT_DIR/spells/install/core/install-dd"

  assert_failure || return 1
  assert_error_contains "unable to install coreutils automatically" || return 1
}

run_test_case "install-dd installs via package manager" install_dd_installs_package
run_test_case "install-dd has content" spell_has_content
run_test_case "install-dd reports failure when package manager fails" install_dd_reports_failure_when_package_manager_fails


shows_help() {
  run_spell spells/install/core/install-dd --help
  true
}

run_test_case "install-dd shows help" shows_help
finish_tests
