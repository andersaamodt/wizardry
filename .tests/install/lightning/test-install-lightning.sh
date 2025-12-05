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
  [ -x "$ROOT_DIR/spells/install/lightning/install-lightning" ]
}
run_test_case "install/lightning/install-lightning is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/lightning/install-lightning" ]
}
run_test_case "install/lightning/install-lightning has content" spell_has_content

shows_usage_help() {
  run_spell spells/install/lightning/install-lightning --help
  assert_success || return 1
  assert_error_contains "Usage: install-lightning"
  assert_error_contains "Lightning (Core Lightning)"
}
run_test_case "install-lightning shows usage help" shows_usage_help

debian_flow_installs_and_reports_success() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  printf '%s\n' "#!/bin/sh\nprintf debian\n" >"$fixture/bin/detect-distro" && chmod +x "$fixture/bin/detect-distro"
  printf '%s\n' "#!/bin/sh\nprintf lightningd\n" >"$fixture/bin/lightning-cli" && chmod +x "$fixture/bin/lightning-cli"

  PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" \
    run_cmd "$ROOT_DIR/spells/install/lightning/install-lightning"

  assert_success || return 1
  assert_output_contains "Detected platform: debian"
  assert_output_contains "Lightning installation complete."
  assert_file_contains "$fixture/log/apt.log" "apt-get update"
  assert_file_contains "$fixture/log/apt.log" "apt-get install -y lightningd"
}
run_test_case "install-lightning installs via apt on Debian" debian_flow_installs_and_reports_success

unsupported_distro_fails_cleanly() {
  fixture=$(make_fixture)
  printf '%s\n' "#!/bin/sh\nprintf haiku\n" >"$fixture/bin/detect-distro" && chmod +x "$fixture/bin/detect-distro"

  PATH="$fixture/bin:$PATH" run_cmd "$ROOT_DIR/spells/install/lightning/install-lightning"

  assert_failure || return 1
}
run_test_case "install-lightning fails on unsupported distro" unsupported_distro_fails_cleanly

finish_tests
