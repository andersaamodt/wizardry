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

install_core_installs_all_missing() {
  fixture=$(_make_fixture)
  _write_apt_stub "$fixture"
  _write_sudo_stub "$fixture"
  _provide_basic_tools "$fixture"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" _run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/.arcana/core/install-core"

  _assert_success || return 1
  installs=$(grep -c "apt-get -y install" "$fixture/log/apt.log" || true)
  [ "$installs" -ge 3 ] || { TEST_FAILURE_REASON="expected multiple system installs"; return 1; }
}

_run_test_case "install-core installs all dependencies" install_core_installs_all_missing

install_core_uses_pkgin_on_darwin() {
  fixture=$(_make_fixture)
  _write_pkgin_stub "$fixture"
  _write_apt_stub "$fixture"
  _write_sudo_stub "$fixture"
  _provide_basic_tools "$fixture"

  cat <<'STUB' >"$fixture/bin/uname"
#!/bin/sh
printf 'Darwin\n'
STUB
  chmod +x "$fixture/bin/uname"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" PKGIN_LOG="$fixture/log/pkgin.log" PKGIN_CANDIDATES="$fixture/opt/pkg/bin/pkgin" _run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" PKGIN_LOG="$fixture/log/pkgin.log" PKGIN_CANDIDATES="$fixture/opt/pkg/bin/pkgin" \
    "$ROOT_DIR/spells/.arcana/core/install-core"

  _assert_success || return 1
  installs=$(grep -c "pkgin install" "$fixture/log/pkgin.log" || true)
  [ "$installs" -ge 3 ] || { TEST_FAILURE_REASON="expected pkgin installs"; return 1; }
  [ ! -s "$fixture/log/apt.log" ] || { TEST_FAILURE_REASON="apt should not run on Darwin"; return 1; }
  [ "$(grep -c bubblewrap "$fixture/log/pkgin.log" || true)" -eq 0 ] || { TEST_FAILURE_REASON="bubblewrap should be skipped on Darwin"; return 1; }
}

_run_test_case "install-core uses pkgin on Darwin" install_core_uses_pkgin_on_darwin

install_core_uses_pacman_on_arch() {
  fixture=$(_make_fixture)
  _write_pacman_stub "$fixture"
  _write_sudo_stub "$fixture"
  _provide_basic_tools "$fixture"
  _link_tools "$fixture/bin" grep uname

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" PACMAN_LOG="$fixture/log/pacman.log" _run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" PACMAN_LOG="$fixture/log/pacman.log" \
    "$ROOT_DIR/spells/.arcana/core/install-core"

  _assert_success || return 1
  installs=$(grep -c "pacman --noconfirm -Sy" "$fixture/log/pacman.log" || true)
  [ "$installs" -ge 3 ] || { TEST_FAILURE_REASON="expected multiple pacman installs"; return 1; }
}

_run_test_case "install-core uses pacman on Arch" install_core_uses_pacman_on_arch

install_core_uses_nix_env_on_nixos() {
  fixture=$(_make_fixture)
  _write_nix_env_stub "$fixture"
  _provide_basic_tools "$fixture"
  _link_tools "$fixture/bin" grep uname

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" MANAGE_SYSTEM_COMMAND_NIXOS=1 NIX_ENV_LOG="$fixture/log/nix-env.log" _run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" MANAGE_SYSTEM_COMMAND_NIXOS=1 NIX_ENV_LOG="$fixture/log/nix-env.log" \
    "$ROOT_DIR/spells/.arcana/core/install-core"

  _assert_success || return 1
  installs=$(grep -c "nix-env -iA nixpkgs" "$fixture/log/nix-env.log" || true)
  [ "$installs" -ge 3 ] || { TEST_FAILURE_REASON="expected multiple nix-env installs"; return 1; }
}

_run_test_case "install-core uses nix-env on NixOS" install_core_uses_nix_env_on_nixos


shows_help() {
  _run_spell spells/.arcana/core/install-core --help
  true
}

_run_test_case "install-core shows help" shows_help
_finish_tests
