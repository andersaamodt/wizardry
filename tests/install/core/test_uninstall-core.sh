#!/bin/sh
set -eu

# shellcheck source=../../test_common.sh
. "$(dirname "$0")/../../test_common.sh"
# shellcheck source=./core_test_helpers.sh
. "$(dirname "$0")/core_test_helpers.sh"

uninstall_core_removes_installed_items() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"
  for cmd in bwrap git menu fathom-cursor fathom-terminal move-cursor await-keypress cursor-blink tput stty dd; do
    write_command_stub "$fixture/bin" "$cmd"
    ln -s "$ROOT_DIR/spells/cantrips/${cmd}" "$fixture/home/.local/bin/$cmd" 2>/dev/null || true
  done

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/install/core/uninstall-core"

  assert_success || return 1
  for cmd in await-keypress menu cursor-blink fathom-cursor fathom-terminal move-cursor; do
    [ ! -e "$fixture/home/.local/bin/$cmd" ] || { TEST_FAILURE_REASON="shim $cmd not removed"; return 1; }
  done
  removes=$(grep -c "apt-get -y remove" "$fixture/log/apt.log" || true)
  [ "$removes" -ge 1 ] || { TEST_FAILURE_REASON="no removals attempted"; return 1; }
}

run_test_case "uninstall-core removes installed dependencies" uninstall_core_removes_installed_items

finish_tests
