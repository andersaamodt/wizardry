#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

make_fixture() {
  fixture=$(make_tempdir)
  mkdir -p "$fixture/bin" "$fixture/log" "$fixture/home/.local/bin"
  printf '%s\n' "$fixture"
}

write_apt_stub() {
  fixture=$1
  cat <<'STUB' >"$fixture/bin/apt-get"
#!/bin/sh
echo "$0 $*" >>"${APT_LOG:?}" || exit 1
exit ${APT_EXIT:-0}
STUB
  chmod +x "$fixture/bin/apt-get"
}

write_sudo_stub() {
  fixture=$1
  cat <<'STUB' >"$fixture/bin/sudo"
#!/bin/sh
exec "$@"
STUB
  chmod +x "$fixture/bin/sudo"
}

write_command_stub() {
  dir=$1
  name=$2
  cat <<'STUB' >"$dir/$name"
#!/bin/sh
exit 0
STUB
  chmod +x "$dir/$name"
}

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

manage_wizardry_installs_shim() {
  fixture=$(make_fixture)
  PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/manage-wizardry-command" shim-test spells/cantrips/await-keypress

  assert_success || return 1
  assert_path_exists "$fixture/home/.local/bin/shim-test" || return 1
}

manage_wizardry_handles_existing_command() {
  fixture=$(make_fixture)
  write_command_stub "$fixture/bin" shim-test

  PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/manage-wizardry-command" shim-test spells/cantrips/await-keypress

  assert_success || return 1
  [ ! -e "$fixture/home/.local/bin/shim-test" ] || { TEST_FAILURE_REASON="shim should not be created"; return 1; }
}

manage_wizardry_uninstalls_shim() {
  fixture=$(make_fixture)
  ln -s "$ROOT_DIR/spells/cantrips/await-keypress" "$fixture/home/.local/bin/shim-test"

  PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/manage-wizardry-command" --uninstall shim-test spells/cantrips/await-keypress

  assert_success || return 1
  [ ! -e "$fixture/home/.local/bin/shim-test" ] || { TEST_FAILURE_REASON="shim should be removed"; return 1; }
}

manage_wizardry_requires_source() {
  fixture=$(make_fixture)
  PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" run_cmd \
    env PATH="$fixture/bin:$PATH" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" \
    "$ROOT_DIR/spells/install/core/manage-wizardry-command" shim-missing spells/does-not-exist

  assert_failure || return 1
  assert_error_contains "does not exist" || return 1
}

install_core_installs_all_missing() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"

  PATH="$fixture/bin:/usr/bin:/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin:/usr/bin:/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/install/core/install-core"

  assert_success || return 1
  # ensure wizardry shims were created
  for cmd in await-keypress menu cursor-blink fathom-cursor fathom-terminal move-cursor; do
    assert_path_exists "$fixture/home/.local/bin/$cmd" || return 1
  done
  installs=$(grep -c "apt-get -y install" "$fixture/log/apt.log" || true)
  [ "$installs" -ge 1 ] || { TEST_FAILURE_REASON="no system installs attempted"; return 1; }
}

uninstall_core_removes_installed_items() {
  fixture=$(make_fixture)
  write_apt_stub "$fixture"
  write_sudo_stub "$fixture"
  # Pretend commands are present
  for cmd in bwrap git menu fathom-cursor fathom-terminal move-cursor await-keypress cursor-blink tput stty dd; do
    write_command_stub "$fixture/bin" "$cmd"
    ln -s "$ROOT_DIR/spells/cantrips/${cmd}" "$fixture/home/.local/bin/$cmd" 2>/dev/null || true
  done

  PATH="$fixture/bin:/usr/bin:/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" run_cmd \
    env PATH="$fixture/bin:/usr/bin:/bin" HOME="$fixture/home" WIZARDRY_BIN_DIR="$fixture/home/.local/bin" APT_LOG="$fixture/log/apt.log" \
    "$ROOT_DIR/spells/install/core/uninstall-core"

  assert_success || return 1
  for cmd in await-keypress menu cursor-blink fathom-cursor fathom-terminal move-cursor; do
    [ ! -e "$fixture/home/.local/bin/$cmd" ] || { TEST_FAILURE_REASON="shim $cmd not removed"; return 1; }
  done
  removes=$(grep -c "apt-get -y remove" "$fixture/log/apt.log" || true)
  [ "$removes" -ge 1 ] || { TEST_FAILURE_REASON="no removals attempted"; return 1; }
}

run_test_case "manage-system-command installs when missing" manage_system_installs_when_missing
run_test_case "manage-system-command skips when present" manage_system_skips_when_present
run_test_case "manage-system-command reports failed installation" manage_system_reports_failure_when_installers_fail
run_test_case "manage-system-command uninstalls when present" manage_system_uninstalls_when_present
run_test_case "manage-system-command reports failed removal" manage_system_reports_failure_when_uninstallers_fail
run_test_case "manage-wizardry-command installs shim" manage_wizardry_installs_shim
run_test_case "manage-wizardry-command returns when command exists" manage_wizardry_handles_existing_command
run_test_case "manage-wizardry-command removes shim" manage_wizardry_uninstalls_shim
run_test_case "manage-wizardry-command requires source" manage_wizardry_requires_source
run_test_case "install-core installs all dependencies" install_core_installs_all_missing
run_test_case "uninstall-core removes installed dependencies" uninstall_core_removes_installed_items

finish_tests
