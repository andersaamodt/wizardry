#!/bin/sh
set -eu

# shellcheck source=../../spells/.imps/test/test-bootstrap
# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

install_xsel_installs_package() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/.arcana/core/install-xsel"

  assert_success || return 1
  assert_file_contains "$fixture/log/apt.log" "apt-get -y install xsel" || return 1
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/core/install-xsel" ]
}

install_xsel_reports_failure_when_package_manager_fails() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  # Force package manager to fail
  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 \
    "$ROOT_DIR/spells/.arcana/core/install-xsel"

  assert_failure || return 1
  assert_error_contains "unable to install xsel automatically" || return 1
}

run_test_case "install-xsel installs via package manager" install_xsel_installs_package
run_test_case "install-xsel has content" spell_has_content
run_test_case "install-xsel reports failure when package manager fails" install_xsel_reports_failure_when_package_manager_fails

shows_help() {
  run_spell spells/.arcana/core/install-xsel --help
  true
}

run_test_case "install-xsel shows help" shows_help
finish_tests
