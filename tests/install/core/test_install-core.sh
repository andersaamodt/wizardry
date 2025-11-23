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
  installs=$(grep -c "apt-get -y install" "$fixture/log/apt.log" || true)
  [ "$installs" -ge 3 ] || { TEST_FAILURE_REASON="expected multiple system installs"; return 1; }
}

run_test_case "install-core installs all dependencies" install_core_installs_all_missing

install_core_uses_brew_on_darwin() {
  fixture=$(make_fixture)
  write_brew_stub "$fixture"
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  cat <<'STUB' >"$fixture/bin/uname"
#!/bin/sh
printf 'Darwin\n'
STUB
  chmod +x "$fixture/bin/uname"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" BREW_LOG="$fixture/log/brew.log" BREW_CANDIDATES="$fixture/opt/homebrew/bin/brew" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" BREW_LOG="$fixture/log/brew.log" BREW_CANDIDATES="$fixture/opt/homebrew/bin/brew" \
    "$ROOT_DIR/spells/install/core/install-core"

  assert_success || return 1
  installs=$(grep -c "brew install" "$fixture/log/brew.log" || true)
  [ "$installs" -ge 3 ] || { TEST_FAILURE_REASON="expected brew installs"; return 1; }
  [ ! -s "$fixture/log/apt.log" ] || { TEST_FAILURE_REASON="apt should not run on Darwin"; return 1; }
  [ "$(grep -c bubblewrap "$fixture/log/brew.log" || true)" -eq 0 ] || { TEST_FAILURE_REASON="bubblewrap should be skipped on Darwin"; return 1; }
}

run_test_case "install-core uses brew on Darwin" install_core_uses_brew_on_darwin

finish_tests
