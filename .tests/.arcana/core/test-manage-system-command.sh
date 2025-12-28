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

manage_system_installs_when_missing() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"

  PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/.arcana/core/manage-system-command" example example-pkg

  assert_success || return 1
  installs=$(grep -c "apt-get -y install example-pkg" "$fixture/log/apt.log" || true)
  [ "$installs" -ge 1 ] || { TEST_FAILURE_REASON="install not attempted"; return 1; }
}

manage_system_skips_when_present() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  write_command_stub "$fixture/bin" example

  PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/.arcana/core/manage-system-command" example example-pkg

  assert_success || return 1
  [ ! -f "$fixture/log/apt.log" ] || { TEST_FAILURE_REASON="installer should not run"; return 1; }
}

manage_system_reports_failure_when_installers_fail() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"

  PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 run_cmd \
    env PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 \
    "$ROOT_DIR/spells/.arcana/core/manage-system-command" example example-pkg

  assert_failure || return 1
  assert_error_contains "unable to install example-pkg automatically" || return 1
}

manage_system_uninstalls_when_present() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  write_command_stub "$fixture/bin" example

  PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/.arcana/core/manage-system-command" --uninstall example example-pkg

  assert_success || return 1
  removes=$(grep -c "apt-get -y remove example-pkg" "$fixture/log/apt.log" || true)
  [ "$removes" -ge 1 ] || { TEST_FAILURE_REASON="remove not attempted"; return 1; }
}

manage_system_reports_failure_when_uninstallers_fail() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  write_command_stub "$fixture/bin" example

  PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 run_cmd \
    env PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 \
    "$ROOT_DIR/spells/.arcana/core/manage-system-command" --uninstall example example-pkg

  assert_failure || return 1
  assert_error_contains "unable to uninstall example" || return 1
}

manage_system_prefers_pkgin_on_darwin() {
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

  PATH="$fixture/bin" PKGIN_LOG="$fixture/log/pkgin.log" APT_LOG="$fixture/log/apt.log" PKGIN_CANDIDATES="$fixture/opt/pkg/bin/pkgin" run_cmd \
    env PATH="$fixture/bin" PKGIN_LOG="$fixture/log/pkgin.log" APT_LOG="$fixture/log/apt.log" PKGIN_CANDIDATES="$fixture/opt/pkg/bin/pkgin" \
    "$ROOT_DIR/spells/.arcana/core/manage-system-command" example example-pkg

  assert_success || return 1
  [ -f "$fixture/log/pkgin.log" ] || { TEST_FAILURE_REASON="pkgin not used"; return 1; }
  [ ! -s "$fixture/log/apt.log" ] || { TEST_FAILURE_REASON="apt should not be used on Darwin"; return 1; }
}

manage_system_prefers_pacman_when_available() {
  fixture=$(make_fixture)
  stub_pacman "$fixture"
  write_sudo_stub "$fixture"
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" grep

  PATH="$fixture/bin" PACMAN_LOG="$fixture/log/pacman.log" run_cmd \
    env PATH="$fixture/bin" PACMAN_LOG="$fixture/log/pacman.log" \
    "$ROOT_DIR/spells/.arcana/core/manage-system-command" example example-pkg

  assert_success || return 1
  installs=$(grep -c "pacman --noconfirm -Sy example-pkg" "$fixture/log/pacman.log" || true)
  [ "$installs" -ge 1 ] || { TEST_FAILURE_REASON="pacman not used"; return 1; }
}

manage_system_uses_nix_env_on_nixos() {
  fixture=$(make_fixture)
  stub_nix_env "$fixture"
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" grep

  PATH="$fixture/bin" MANAGE_SYSTEM_COMMAND_NIXOS=1 NIX_ENV_LOG="$fixture/log/nix-env.log" run_cmd \
    env PATH="$fixture/bin" MANAGE_SYSTEM_COMMAND_NIXOS=1 NIX_ENV_LOG="$fixture/log/nix-env.log" \
    "$ROOT_DIR/spells/.arcana/core/manage-system-command" example example-pkg

  assert_success || return 1
  installs=$(grep -c "nix-env -iA nixpkgs.example-pkg" "$fixture/log/nix-env.log" || true)
  [ "$installs" -ge 1 ] || { TEST_FAILURE_REASON="nix-env not used"; return 1; }
}

manage_system_rejects_missing_arguments() {
  # No arguments should trigger usage error
  run_cmd "$ROOT_DIR/spells/.arcana/core/manage-system-command"
  assert_failure || return 1
  assert_error_contains "Usage: manage-system-command" || return 1
}

manage_system_rejects_single_argument() {
  # One argument is not enough - need both command and package
  run_cmd "$ROOT_DIR/spells/.arcana/core/manage-system-command" some-command
  assert_failure || return 1
  assert_error_contains "Usage: manage-system-command" || return 1
}

run_test_case "manage-system-command rejects missing arguments" manage_system_rejects_missing_arguments
run_test_case "manage-system-command rejects single argument" manage_system_rejects_single_argument
run_test_case "manage-system-command installs when missing" manage_system_installs_when_missing
run_test_case "manage-system-command skips when present" manage_system_skips_when_present
run_test_case "manage-system-command reports failed installation" manage_system_reports_failure_when_installers_fail
run_test_case "manage-system-command uninstalls when present" manage_system_uninstalls_when_present
run_test_case "manage-system-command reports failed removal" manage_system_reports_failure_when_uninstallers_fail
run_test_case "manage-system-command uses pkgin on Darwin" manage_system_prefers_pkgin_on_darwin
run_test_case "manage-system-command uses pacman when available" manage_system_prefers_pacman_when_available
run_test_case "manage-system-command uses nix-env on NixOS" manage_system_uses_nix_env_on_nixos

shows_help() {
  run_spell spells/.arcana/core/manage-system-command --help
  true
}

run_test_case "manage-system-command shows help" shows_help
finish_tests
