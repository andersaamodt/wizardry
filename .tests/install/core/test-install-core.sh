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
    "$ROOT_DIR/spells/install/core/install-core"

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
    "$ROOT_DIR/spells/install/core/install-core"

  assert_success || return 1
  installs=$(grep -c "pkgin install" "$fixture/log/pkgin.log" || true)
  [ "$installs" -ge 3 ] || { TEST_FAILURE_REASON="expected pkgin installs"; return 1; }
  [ ! -s "$fixture/log/apt.log" ] || { TEST_FAILURE_REASON="apt should not run on Darwin"; return 1; }
  [ "$(grep -c bubblewrap "$fixture/log/pkgin.log" || true)" -eq 0 ] || { TEST_FAILURE_REASON="bubblewrap should be skipped on Darwin"; return 1; }
}

run_test_case "install-core uses pkgin on Darwin" install_core_uses_pkgin_on_darwin


shows_help() {
  run_spell spells/install/core/install-core --help
  true
}

run_test_case "install-core shows help" shows_help
finish_tests
