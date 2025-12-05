#!/bin/sh
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
    "$ROOT_DIR/spells/install/core/manage-system-command" example example-pkg

  assert_success || return 1
  [ -f "$fixture/log/pkgin.log" ] || { TEST_FAILURE_REASON="pkgin not used"; return 1; }
  [ ! -s "$fixture/log/apt.log" ] || { TEST_FAILURE_REASON="apt should not be used on Darwin"; return 1; }
}

manage_system_rejects_missing_arguments() {
  # No arguments should trigger usage error
  run_cmd "$ROOT_DIR/spells/install/core/manage-system-command"
  assert_failure || return 1
  assert_error_contains "Usage: manage-system-command" || return 1
}

manage_system_rejects_single_argument() {
  # One argument is not enough - need both command and package
  run_cmd "$ROOT_DIR/spells/install/core/manage-system-command" some-command
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

shows_help() {
  run_spell spells/install/core/manage-system-command --help
  true
}

run_test_case "manage-system-command shows help" shows_help
finish_tests
