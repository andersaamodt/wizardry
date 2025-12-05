#!/bin/sh
# Behavioral cases (derived from --help):
# - install-bwrap exits early when already installed
# - install-bwrap tries package manager when missing
# - install-bwrap reports failure when no installer is available
# - install-bwrap rejects unknown options

set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


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
