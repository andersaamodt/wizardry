#!/bin/sh
set -eu

# shellcheck source=../../test-common.sh
. "$(dirname "$0")/../../test-common.sh"

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

uninstall_core_uses_pkgin_on_darwin() {
  fixture=$(make_fixture)
  write_pkgin_stub "$fixture"
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

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" PKGIN_LOG="$fixture/log/pkgin.log" PKGIN_CANDIDATES="$fixture/opt/pkg/bin/pkgin" run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" PKGIN_LOG="$fixture/log/pkgin.log" PKGIN_CANDIDATES="$fixture/opt/pkg/bin/pkgin" \
    "$ROOT_DIR/spells/install/core/uninstall-core"

  assert_success || return 1
  [ -f "$fixture/log/pkgin.log" ] || { TEST_FAILURE_REASON="pkgin not used"; return 1; }
  [ "$(grep -c bubblewrap "$fixture/log/pkgin.log" || true)" -eq 0 ] || { TEST_FAILURE_REASON="bubblewrap should not be removed on Darwin"; return 1; }
  [ ! -s "$fixture/log/apt.log" ] || { TEST_FAILURE_REASON="apt should not run on Darwin"; return 1; }
}

run_test_case "uninstall-core uses pkgin on Darwin" uninstall_core_uses_pkgin_on_darwin

spell_has_shebang() {
  head -1 "$ROOT_DIR/spells/install/core/uninstall-core" | grep -q "^#!"
}

run_test_case "install/core/uninstall-core has shebang" spell_has_shebang
finish_tests
