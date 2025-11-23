#!/bin/sh
set -eu

# shellcheck source=../../test_common.sh
. "$(dirname "$0")/../../test_common.sh"

uninstall_core_removes_installed_items() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"
  for cmd in bwrap git tput stty dd; do
    write_command_stub "$fixture/bin" "$cmd"
  done

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/install/core/uninstall-core"

  assert_success || return 1
  removes=$(grep -c "apt-get -y remove" "$fixture/log/apt.log" || true)
  [ "$removes" -ge 1 ] || { TEST_FAILURE_REASON="no removals attempted"; return 1; }
}

run_test_case "uninstall-core removes installed dependencies" uninstall_core_removes_installed_items

uninstall_core_uses_brew_on_darwin() {
  fixture=$(make_fixture)
  write_brew_stub "$fixture"
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"
  for cmd in git tput stty dd; do
    write_command_stub "$fixture/bin" "$cmd"
  done

  cat <<'STUB' >"$fixture/bin/uname"
#!/bin/sh
printf 'Darwin\n'
STUB
  chmod +x "$fixture/bin/uname"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" BREW_LOG="$fixture/log/brew.log" BREW_CANDIDATES="$fixture/opt/homebrew/bin/brew" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" BREW_LOG="$fixture/log/brew.log" BREW_CANDIDATES="$fixture/opt/homebrew/bin/brew" \
    "$ROOT_DIR/spells/install/core/uninstall-core"

  assert_success || return 1
  [ -f "$fixture/log/brew.log" ] || { TEST_FAILURE_REASON="brew not used"; return 1; }
  [ "$(grep -c bubblewrap "$fixture/log/brew.log" || true)" -eq 0 ] || { TEST_FAILURE_REASON="bubblewrap should not be removed on Darwin"; return 1; }
  [ ! -s "$fixture/log/apt.log" ] || { TEST_FAILURE_REASON="apt should not run on Darwin"; return 1; }
}

run_test_case "uninstall-core uses brew on Darwin" uninstall_core_uses_brew_on_darwin

finish_tests
