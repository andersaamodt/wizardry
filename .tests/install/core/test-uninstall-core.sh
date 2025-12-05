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

uninstall_core_removes_installed_items() {
  fixture=$(_make_fixture)
  _write_apt_stub "$fixture"
  _write_sudo_stub "$fixture"
  _provide_basic_tools "$fixture"
  for cmd in bwrap git tput stty dd; do
    _write_command_stub "$fixture/bin" "$cmd"
  done

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" _run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/install/core/uninstall-core"

  _assert_success || return 1
  removes=$(grep -c "apt-get -y remove" "$fixture/log/apt.log" || true)
  [ "$removes" -ge 1 ] || { TEST_FAILURE_REASON="no removals attempted"; return 1; }
}

_run_test_case "uninstall-core removes installed dependencies" uninstall_core_removes_installed_items

uninstall_core_uses_pkgin_on_darwin() {
  fixture=$(_make_fixture)
  _write_pkgin_stub "$fixture"
  _write_apt_stub "$fixture"
  _write_sudo_stub "$fixture"
  _provide_basic_tools "$fixture"
  for cmd in git tput stty dd; do
    _write_command_stub "$fixture/bin" "$cmd"
  done

  cat <<'STUB' >"$fixture/bin/uname"
#!/bin/sh
printf 'Darwin\n'
STUB
  chmod +x "$fixture/bin/uname"

  PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" PKGIN_LOG="$fixture/log/pkgin.log" PKGIN_CANDIDATES="$fixture/opt/pkg/bin/pkgin" _run_cmd \
    env PATH="$fixture/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" PKGIN_LOG="$fixture/log/pkgin.log" PKGIN_CANDIDATES="$fixture/opt/pkg/bin/pkgin" \
    "$ROOT_DIR/spells/install/core/uninstall-core"

  _assert_success || return 1
  [ -f "$fixture/log/pkgin.log" ] || { TEST_FAILURE_REASON="pkgin not used"; return 1; }
  [ "$(grep -c bubblewrap "$fixture/log/pkgin.log" || true)" -eq 0 ] || { TEST_FAILURE_REASON="bubblewrap should not be removed on Darwin"; return 1; }
  [ ! -s "$fixture/log/apt.log" ] || { TEST_FAILURE_REASON="apt should not run on Darwin"; return 1; }
}

_run_test_case "uninstall-core uses pkgin on Darwin" uninstall_core_uses_pkgin_on_darwin


shows_help() {
  _run_spell spells/install/core/uninstall-core --help
  true
}

_run_test_case "uninstall-core shows help" shows_help
_finish_tests
