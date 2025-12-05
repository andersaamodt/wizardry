#!/bin/sh
# Tests for toggle-cd spell
# Behavioral cases:
# - toggle-cd installs the hook when not present
# - toggle-cd uninstalls the hook when present
# - toggle-cd --help shows usage

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


test_toggle_cd_is_executable() {
  [ -x "$ROOT_DIR/spells/install/mud/toggle-cd" ]
}

test_toggle_cd_requires_cd_spell() {
  content=$(cat "$ROOT_DIR/spells/install/mud/toggle-cd")
  case "$content" in
    *CD_SPELL*cd*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="toggle-cd should reference the cd spell"
      return 1
      ;;
  esac
}

test_toggle_cd_has_install_and_uninstall() {
  content=$(cat "$ROOT_DIR/spells/install/mud/toggle-cd")
  case "$content" in
    *install*uninstall*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="toggle-cd should handle both install and uninstall"
      return 1
      ;;
  esac
}

test_toggle_cd_installs_when_not_present() {
  tmp=$(make_tempdir)
  # Create an empty rc file without the hook
  : >"$tmp/rc"
  
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/toggle-cd"
  assert_success || return 1
  assert_output_contains "cd hook enabled" || return 1
  
  # Verify hook was installed
  if ! grep -q ">>> wizardry cd cantrip >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook not installed after toggle"
    return 1
  fi
}

test_toggle_cd_uninstalls_when_present() {
  tmp=$(make_tempdir)
  
  # First install the hook
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/cd" install
  assert_success || return 1
  
  # Now toggle should uninstall it
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/toggle-cd"
  assert_success || return 1
  assert_output_contains "cd hook disabled" || return 1
  
  # Verify hook was removed
  if grep -q ">>> wizardry cd cantrip >>>" "$tmp/rc"; then
    TEST_FAILURE_REASON="Hook still present after toggle off"
    return 1
  fi
}

test_toggle_cd_help_shows_usage() {
  run_spell spells/install/mud/toggle-cd --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "toggle" || return 1
}

test_toggle_cd_shows_installing_message() {
  tmp=$(make_tempdir)
  # Create an empty rc file without the hook
  : >"$tmp/rc"
  
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/toggle-cd"
  assert_success || return 1
  # Verify it shows the progress message before install
  assert_output_contains "Installing cd hook" || return 1
}

test_toggle_cd_shows_uninstalling_message() {
  tmp=$(make_tempdir)
  
  # First install the hook
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/cd" install
  assert_success || return 1
  
  # Now toggle should uninstall it and show a progress message
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/install/mud/toggle-cd"
  assert_success || return 1
  # Verify it shows the progress message before uninstall
  assert_output_contains "Uninstalling cd hook" || return 1
}

run_test_case "toggle-cd is executable" test_toggle_cd_is_executable
run_test_case "toggle-cd requires cd spell" test_toggle_cd_requires_cd_spell
run_test_case "toggle-cd handles install and uninstall" test_toggle_cd_has_install_and_uninstall
run_test_case "toggle-cd installs when not present" test_toggle_cd_installs_when_not_present
run_test_case "toggle-cd uninstalls when present" test_toggle_cd_uninstalls_when_present
run_test_case "toggle-cd --help shows usage" test_toggle_cd_help_shows_usage
run_test_case "toggle-cd shows installing message" test_toggle_cd_shows_installing_message
run_test_case "toggle-cd shows uninstalling message" test_toggle_cd_shows_uninstalling_message
finish_tests
