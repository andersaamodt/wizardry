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
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/.arcana/core/install-core"

  assert_success || return 1
  installs=$(grep -c "apt-get -y install" "$fixture/log/apt.log" || true)
  [ "$installs" -ge 3 ] || { TEST_FAILURE_REASON="expected multiple system installs"; return 1; }
}

run_test_case "install-core installs all dependencies" install_core_installs_all_missing

install_core_uses_pkgin_on_darwin() {
  fixture=$(make_fixture)
  write_pkgin_stub "$fixture"
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"

  cat <<'STUB' >"$fixture/bin/uname"
#!/bin/sh
printf 'Darwin\n'
STUB
  chmod +x "$fixture/bin/uname"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" PKGIN_LOG="$fixture/log/pkgin.log" PKGIN_CANDIDATES="$fixture/opt/pkg/bin/pkgin" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" PKGIN_LOG="$fixture/log/pkgin.log" PKGIN_CANDIDATES="$fixture/opt/pkg/bin/pkgin" \
    "$ROOT_DIR/spells/.arcana/core/install-core"

  assert_success || return 1
  installs=$(grep -c "pkgin install" "$fixture/log/pkgin.log" || true)
  [ "$installs" -ge 3 ] || { TEST_FAILURE_REASON="expected pkgin installs"; return 1; }
  [ ! -s "$fixture/log/apt.log" ] || { TEST_FAILURE_REASON="apt should not run on Darwin"; return 1; }
}

run_test_case "install-core uses pkgin on Darwin" install_core_uses_pkgin_on_darwin

install_core_uses_pacman_on_arch() {
  fixture=$(make_fixture)
  stub_pacman "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" grep
  rm -f "$fixture/bin/uname" "$fixture/bin/detect-distro"

  cat <<'STUB' >"$fixture/bin/uname"
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$fixture/bin/uname"

  cat <<'STUB' >"$fixture/bin/detect-distro"
#!/bin/sh
printf 'arch\n'
STUB
  chmod +x "$fixture/bin/detect-distro"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" PACMAN_LOG="$fixture/log/pacman.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" PACMAN_LOG="$fixture/log/pacman.log" \
    "$ROOT_DIR/spells/.arcana/core/install-core"

  assert_success || return 1
  installs=$(grep -c "pacman --noconfirm -Sy" "$fixture/log/pacman.log" || true)
  [ "$installs" -ge 3 ] || { TEST_FAILURE_REASON="expected multiple pacman installs"; return 1; }
}

run_test_case "install-core uses pacman on Arch" install_core_uses_pacman_on_arch

install_core_uses_nix_env_on_nixos() {
  fixture=$(make_fixture)
  stub_nix_env "$fixture"
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" grep uname

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" MANAGE_SYSTEM_COMMAND_NIXOS=1 NIX_ENV_LOG="$fixture/log/nix-env.log" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" MANAGE_SYSTEM_COMMAND_NIXOS=1 NIX_ENV_LOG="$fixture/log/nix-env.log" \
    "$ROOT_DIR/spells/.arcana/core/install-core"

  assert_success || return 1
  installs=$(grep -c "nix-env -iA nixpkgs" "$fixture/log/nix-env.log" || true)
  [ "$installs" -ge 3 ] || { TEST_FAILURE_REASON="expected multiple nix-env installs"; return 1; }
}

run_test_case "install-core uses nix-env on NixOS" install_core_uses_nix_env_on_nixos

install_core_skips_bwrap_on_termux() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" grep cat chmod mkdir rm printf env pwd dirname basename test sh
  rm -f "$fixture/bin/uname" "$fixture/bin/detect-distro"

  cat <<'STUB' >"$fixture/bin/uname"
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$fixture/bin/uname"

  cat <<'STUB' >"$fixture/bin/detect-distro"
#!/bin/sh
printf 'termux\n'
STUB
  chmod +x "$fixture/bin/detect-distro"

  install_log="$fixture/log/install.log"
  for spell in install-git install-clipboard-helper install-bwrap install-checkbashisms install-sed \
    install-awk install-grep install-find install-dd install-stty install-tput install-ps install-socat; do
    cat <<'STUB' >"$fixture/bin/$spell"
#!/bin/sh
printf '%s\n' "${0##*/}" >>"${INSTALL_LOG:?}"
exit 0
STUB
    chmod +x "$fixture/bin/$spell"
  done

  run_cmd env PATH="$fixture/bin:/bin:/usr/bin" INSTALL_LOG="$install_log" \
    "$ROOT_DIR/spells/.arcana/core/install-core"

  assert_success || return 1
  assert_path_exists "$install_log" || return 1
  case "$(cat "$install_log")" in
    *install-bwrap*)
      TEST_FAILURE_REASON="did not expect install-core to request bwrap on Termux"
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

install_core_requests_bwrap_on_non_termux_linux() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" grep cat chmod mkdir rm printf env pwd dirname basename test sh
  rm -f "$fixture/bin/uname" "$fixture/bin/detect-distro"

  cat <<'STUB' >"$fixture/bin/uname"
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$fixture/bin/uname"

  cat <<'STUB' >"$fixture/bin/detect-distro"
#!/bin/sh
printf 'debian\n'
STUB
  chmod +x "$fixture/bin/detect-distro"

  install_log="$fixture/log/install.log"
  for spell in install-git install-clipboard-helper install-bwrap install-checkbashisms install-sed \
    install-awk install-grep install-find install-dd install-stty install-tput install-ps install-socat; do
    cat <<'STUB' >"$fixture/bin/$spell"
#!/bin/sh
printf '%s\n' "${0##*/}" >>"${INSTALL_LOG:?}"
exit 0
STUB
    chmod +x "$fixture/bin/$spell"
  done

  run_cmd env PATH="$fixture/bin:/bin:/usr/bin" INSTALL_LOG="$install_log" \
    "$ROOT_DIR/spells/.arcana/core/install-core"

  assert_success || return 1
  assert_file_contains "$install_log" "install-bwrap"
}

run_test_case "install-core skips bwrap auto-install on Termux" install_core_skips_bwrap_on_termux
run_test_case "install-core still requests bwrap on non-Termux Linux" install_core_requests_bwrap_on_non_termux_linux


shows_help() {
  run_spell spells/.arcana/core/install-core --help
  true
}

run_test_case "install-core shows help" shows_help
finish_tests
