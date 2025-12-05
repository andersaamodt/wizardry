#!/bin/sh
set -eu

# Locate repo root
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/tor/install-tor" ]
}
run_test_case "install/tor/install-tor is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/tor/install-tor" ]
}
run_test_case "install/tor/install-tor has content" spell_has_content

shows_usage_help() {
  run_spell spells/install/tor/install-tor --help
  assert_success || return 1
  assert_error_contains "Usage: install-tor"
  assert_error_contains "installing Tor"
}
run_test_case "install-tor shows usage help" shows_usage_help

debian_flow_installs_tor_and_reports() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  printf '%s\n' "#!/bin/sh\nprintf debian\n" >"$fixture/bin/detect-distro" && chmod +x "$fixture/bin/detect-distro"
  printf '%s\n' "#!/bin/sh\nprintf tor\n" >"$fixture/bin/tor" && chmod +x "$fixture/bin/tor"

  PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" \
    run_cmd "$ROOT_DIR/spells/install/tor/install-tor"

  assert_success || return 1
  assert_output_contains "Detected platform: debian"
  assert_output_contains "Tor installation complete."
  assert_file_contains "$fixture/log/apt.log" "apt-get update"
  assert_file_contains "$fixture/log/apt.log" "apt-get install -y tor"
}
run_test_case "install-tor installs via apt on Debian" debian_flow_installs_tor_and_reports

unsupported_distro_fails_cleanly() {
  sandbox=$(mktemp -d "${WIZARDRY_TMPDIR:-/tmp}/tor-unsupported.XXXXXX")
  mkdir -p "$sandbox/bin"
  cat >"$sandbox/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'amigaos'
STUB
  chmod +x "$sandbox/bin/detect-distro"

  set +e
  OUTPUT=$(PATH="$sandbox/bin:$PATH" "$ROOT_DIR/spells/install/tor/install-tor" 2>&1)
  STATUS=$?
  set -e
  rm -rf "$sandbox"

  if [ "$STATUS" -eq 0 ]; then
    TEST_FAILURE_REASON="install-tor should fail on unsupported distro"
    return 1
  fi

  case "$OUTPUT" in
    *"Unsupported distribution for automatic Tor installation."*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="Missing unsupported distribution message"
      return 1
      ;;
  esac
}
run_test_case "install-tor fails on unsupported distro" unsupported_distro_fails_cleanly

finish_tests
