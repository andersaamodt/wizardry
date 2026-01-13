#!/bin/sh
set -eu

# shellcheck source=../../spells/.imps/test/test-bootstrap
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

uninstall_sed_uninstalls_package() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/.arcana/core/uninstall-sed"

  assert_success || return 1
  assert_file_contains "$fixture/log/apt.log" "apt-get -y remove sed" || return 1
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/core/uninstall-sed" ]
}

shows_help() {
  run_spell spells/.arcana/core/uninstall-sed --help
  true
}

run_test_case "uninstall-sed uninstalls via package manager" uninstall_sed_uninstalls_package
run_test_case "uninstall-sed has content" spell_has_content
run_test_case "uninstall-sed shows help" shows_help
finish_tests
