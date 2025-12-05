#!/bin/sh
# Behavioral cases (derived from --help):
# - install-bwrap exits early when already installed
# - install-bwrap tries package manager when missing
# - install-bwrap reports failure when no installer is available
# - install-bwrap rejects unknown options

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

install_bwrap_exits_when_already_installed() {
  fixture=$(make_tempdir)
  mkdir -p "$fixture/bin"
  cat <<'STUB' >"$fixture/bin/bwrap"
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/bwrap"

  PATH="$fixture/bin:$PATH" run_spell "spells/install/core/install-bwrap"
  assert_success || return 1
}

install_bwrap_runs_package_installer() {
  fixture=$(make_tempdir)
  mkdir -p "$fixture/bin" "$fixture/log"

  cat <<'STUB' >"$fixture/bin/apt-get"
#!/bin/sh
echo "$0 $*" >>"${APT_LOG:?}" || exit 1
exit 0
STUB
  chmod +x "$fixture/bin/apt-get"

  cat <<'STUB' >"$fixture/bin/sudo"
#!/bin/sh
exec "$@"
STUB
  chmod +x "$fixture/bin/sudo"

  PATH="$fixture/bin:$PATH" INSTALL_BWRAP_FORCE_INSTALL=1 APT_LOG="$fixture/log/apt.log" run_spell "spells/install/core/install-bwrap"
  assert_success || return 1
  assert_path_exists "$fixture/log/apt.log" || return 1
  updates=$(grep -c "apt-get -y update" "$fixture/log/apt.log" || true)
  installs=$(grep -c "apt-get -y install bubblewrap" "$fixture/log/apt.log" || true)
  [ "$updates" -ge 1 ] || { TEST_FAILURE_REASON="apt-get update not attempted"; return 1; }
  [ "$installs" -ge 1 ] || { TEST_FAILURE_REASON="apt-get install not attempted"; return 1; }
}

install_bwrap_reports_when_no_installer_available() {
  fixture=$(make_tempdir)
  mkdir -p "$fixture/bin"

  for tool in apt-get dnf yum zypper pacman apk pkgin; do
    cat <<'STUB' >"$fixture/bin/$tool"
#!/bin/sh
exit 1
STUB
    chmod +x "$fixture/bin/$tool"
  done

  cat <<'STUB' >"$fixture/bin/sudo"
#!/bin/sh
exec "$@"
STUB
  chmod +x "$fixture/bin/sudo"

  PATH="$fixture/bin:/usr/bin:/bin" INSTALL_BWRAP_FORCE_INSTALL=1 run_spell "spells/install/core/install-bwrap"
  assert_failure || return 1
  assert_error_contains "unable to install bubblewrap automatically" || return 1
}

install_bwrap_rejects_unknown_option() {
  run_spell "spells/install/core/install-bwrap" --unknown
  assert_failure || return 1
  assert_error_contains "unknown option" || return 1
}

run_test_case "install-bwrap exits early when already installed" install_bwrap_exits_when_already_installed
run_test_case "install-bwrap tries package manager when missing" install_bwrap_runs_package_installer
run_test_case "install-bwrap reports failure when no installer is available" install_bwrap_reports_when_no_installer_available
run_test_case "install-bwrap rejects unknown options" install_bwrap_rejects_unknown_option

shows_help() {
  run_spell spells/install/core/install-bwrap --help
  true
}

run_test_case "install-bwrap shows help" shows_help
finish_tests
