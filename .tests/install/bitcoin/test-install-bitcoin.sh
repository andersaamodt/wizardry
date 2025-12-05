#!/bin/sh
set -eu

# Locate test root to source helpers
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/bitcoin/install-bitcoin" ]
}
run_test_case "install/bitcoin/install-bitcoin is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/bitcoin/install-bitcoin" ]
}
run_test_case "install/bitcoin/install-bitcoin has content" spell_has_content

shows_usage_help() {
  run_spell spells/install/bitcoin/install-bitcoin --help
  assert_success || return 1
  assert_error_contains "Usage: install-bitcoin"
  assert_error_contains "install Bitcoin Core"
}
run_test_case "install-bitcoin shows usage help" shows_usage_help

package_manager_flow_uses_apt() {
  fixture=$(make_fixture)
  cat >"$fixture/bin/apt" <<'STUB'
#!/bin/sh
echo "apt $*" >>"${APT_LOG:?}" || exit 1
exit 0
STUB
  chmod +x "$fixture/bin/apt"
  write_sudo_stub "$fixture"
  detect="$fixture/bin/detect-distro"
  printf '%s\n' "#!/bin/sh\nprintf debian\n" >"$detect"
  chmod +x "$detect"

  PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" \
    run_cmd sh -c "printf '\ny\nn\nn\n' | \"$ROOT_DIR/spells/install/bitcoin/install-bitcoin\""

  assert_success || return 1
  assert_output_contains "Detected platform: debian"
  assert_file_contains "$fixture/log/apt.log" "apt update"
  assert_file_contains "$fixture/log/apt.log" "apt install -y bitcoind bitcoin-qt"
}
run_test_case "install-bitcoin installs via apt when requested" package_manager_flow_uses_apt

binary_flow_downloads_expected_tarball() {
  fixture=$(make_fixture)
  for tool in wget tar install; do
    cat >"$fixture/bin/$tool" <<'STUB'
#!/bin/sh
echo "$0 $*" >>"${BIN_LOG:?}" || exit 1
exit 0
STUB
    chmod +x "$fixture/bin/$tool"
  done
  write_sudo_stub "$fixture"
  printf '%s\n' "#!/bin/sh\nprintf x86_64\n" >"$fixture/bin/uname" && chmod +x "$fixture/bin/uname"
  printf '%s\n' "#!/bin/sh\nprintf linux\n" >"$fixture/bin/detect-distro" && chmod +x "$fixture/bin/detect-distro"

  PATH="$fixture/bin:$PATH" BIN_LOG="$fixture/log/bin.log" \
    run_cmd sh -c "printf '\nn\nn\nn\n' | \"$ROOT_DIR/spells/install/bitcoin/install-bitcoin\""

  assert_success || return 1
  assert_output_contains "Bitcoin Core version 25.0 installed from upstream binaries."
  assert_file_contains "$fixture/log/bin.log" "bitcoincore.org/bin/bitcoin-core-"
  assert_file_contains "$fixture/log/bin.log" "-x86_64-linux-gnu.tar.gz"
}
run_test_case "install-bitcoin falls back to upstream binary when declined package manager" binary_flow_downloads_expected_tarball

finish_tests
