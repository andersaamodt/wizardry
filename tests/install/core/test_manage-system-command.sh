#!/bin/sh
set -eu

# shellcheck source=../../test_common.sh
. "$(dirname "$0")/../../test_common.sh"

manage_system_installs_when_missing() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"

  PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/install/core/manage-system-command" example example-pkg

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
    "$ROOT_DIR/spells/install/core/manage-system-command" example example-pkg

  assert_success || return 1
  [ ! -f "$fixture/log/apt.log" ] || { TEST_FAILURE_REASON="installer should not run"; return 1; }
}

manage_system_reports_failure_when_installers_fail() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"

  PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 run_cmd \
    env PATH="$fixture/bin:$PATH" APT_LOG="$fixture/log/apt.log" APT_EXIT=1 \
    "$ROOT_DIR/spells/install/core/manage-system-command" example example-pkg

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
    "$ROOT_DIR/spells/install/core/manage-system-command" --uninstall example example-pkg

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
    "$ROOT_DIR/spells/install/core/manage-system-command" --uninstall example example-pkg

  assert_failure || return 1
  assert_error_contains "unable to uninstall example" || return 1
}

run_test_case "manage-system-command installs when missing" manage_system_installs_when_missing
run_test_case "manage-system-command skips when present" manage_system_skips_when_present
run_test_case "manage-system-command reports failed installation" manage_system_reports_failure_when_installers_fail
run_test_case "manage-system-command uninstalls when present" manage_system_uninstalls_when_present
run_test_case "manage-system-command reports failed removal" manage_system_reports_failure_when_uninstallers_fail

finish_tests
