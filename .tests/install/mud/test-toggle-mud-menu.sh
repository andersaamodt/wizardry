#!/bin/sh
# Tests for toggle-mud-menu - Toggle MUD visibility in main menu

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


test_help_shows_usage() {
  run_spell "spells/install/mud/toggle-mud-menu" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "MUD" || return 1
}

test_toggle_enables_mud_menu() {
  tmp=$(make_tempdir)
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-mud-menu"
  assert_success || return 1
  assert_output_contains "enabled" || return 1
}

test_toggle_disables_mud_menu() {
  tmp=$(make_tempdir)
  # First enable
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-mud-menu"
  assert_success || return 1
  
  # Then disable
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-mud-menu"
  assert_success || return 1
  assert_output_contains "hidden" || return 1
}

test_fails_when_mud_config_missing() {
  tmp=$(make_tempdir)
  # Copy the toggle script to a temp location without mud-config
  cp "$ROOT_DIR/spells/install/mud/toggle-mud-menu" "$tmp/toggle-mud-menu"
  chmod +x "$tmp/toggle-mud-menu"
  
  run_cmd env MUD_DIR="$tmp" "$tmp/toggle-mud-menu"
  assert_failure || return 1
  assert_error_contains "mud-config not found" || return 1
}

run_test_case "toggle-mud-menu --help shows usage" test_help_shows_usage
run_test_case "toggle-mud-menu enables MUD in main menu" test_toggle_enables_mud_menu
run_test_case "toggle-mud-menu toggles MUD off" test_toggle_disables_mud_menu
run_test_case "toggle-mud-menu fails when mud-config missing" test_fails_when_mud_config_missing

finish_tests
