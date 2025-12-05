#!/bin/sh
# Tests for toggle-all-mud - Enable/disable all MUD features at once

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
  run_spell "spells/install/mud/toggle-all-mud" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "--enable" || return 1
  assert_output_contains "--disable" || return 1
}

test_enable_flag_enables_all() {
  tmp=$(make_tempdir)
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-all-mud" --enable
  assert_success || return 1
  assert_output_contains "All MUD features enabled" || return 1
  
  # Verify all features are enabled
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/mud-config" list
  assert_success || return 1
  assert_output_contains "command-not-found=1" || return 1
  assert_output_contains "touch-hook=1" || return 1
  assert_output_contains "fantasy-theme=1" || return 1
  assert_output_contains "inventory=1" || return 1
  assert_output_contains "combat=1" || return 1
}

test_disable_flag_disables_all() {
  tmp=$(make_tempdir)
  # First enable all features
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-all-mud" --enable
  assert_success || return 1
  
  # Then disable all
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-all-mud" --disable
  assert_success || return 1
  assert_output_contains "All MUD features disabled" || return 1
  
  # Verify all features are disabled
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/mud-config" list
  assert_success || return 1
  assert_output_contains "command-not-found=0" || return 1
  assert_output_contains "touch-hook=0" || return 1
  assert_output_contains "fantasy-theme=0" || return 1
  assert_output_contains "inventory=0" || return 1
  assert_output_contains "combat=0" || return 1
}

test_auto_toggle_enables_when_any_disabled() {
  tmp=$(make_tempdir)
  # Start with all disabled (default state)
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-all-mud"
  assert_success || return 1
  assert_output_contains "All MUD features enabled" || return 1
}

test_auto_toggle_disables_when_all_enabled() {
  tmp=$(make_tempdir)
  # First enable all
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-all-mud" --enable
  assert_success || return 1
  
  # Auto-toggle should disable
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-all-mud"
  assert_success || return 1
  assert_output_contains "All MUD features disabled" || return 1
}

run_test_case "toggle-all-mud --help shows usage" test_help_shows_usage
run_test_case "toggle-all-mud --enable enables all features" test_enable_flag_enables_all
run_test_case "toggle-all-mud --disable disables all features" test_disable_flag_disables_all
run_test_case "toggle-all-mud auto-enables when any disabled" test_auto_toggle_enables_when_any_disabled
run_test_case "toggle-all-mud auto-disables when all enabled" test_auto_toggle_disables_when_all_enabled

finish_tests
