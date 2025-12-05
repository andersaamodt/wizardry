#!/bin/sh
# Tests for mud-config - MUD feature configuration management

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
  run_spell "spells/install/mud/mud-config" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "get" || return 1
}

test_get_returns_disabled_by_default() {
  tmp=$(make_tempdir)
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/mud-config" get combat
  assert_success || return 1
  assert_output_contains "0" || return 1
}

test_set_enables_feature() {
  tmp=$(make_tempdir)
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/mud-config" set combat 1
  assert_success || return 1
  
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/mud-config" get combat
  assert_success || return 1
  assert_output_contains "1" || return 1
}

test_toggle_flips_state() {
  tmp=$(make_tempdir)
  
  # Toggle from disabled to enabled
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/mud-config" toggle combat
  assert_success || return 1
  assert_output_contains "1" || return 1
  
  # Toggle from enabled to disabled
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/mud-config" toggle combat
  assert_success || return 1
  assert_output_contains "0" || return 1
}

test_list_shows_all_features() {
  tmp=$(make_tempdir)
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/mud-config" list
  assert_success || return 1
  assert_output_contains "command-not-found=" || return 1
  assert_output_contains "touch-hook=" || return 1
  assert_output_contains "fantasy-theme=" || return 1
  assert_output_contains "inventory=" || return 1
  assert_output_contains "combat=" || return 1
}

test_invalid_value_rejected() {
  tmp=$(make_tempdir)
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/mud-config" set combat invalid
  assert_failure || return 1
  assert_error_contains "must be '1' or '0'" || return 1
}

run_test_case "mud-config --help shows usage" test_help_shows_usage
run_test_case "mud-config get returns disabled by default" test_get_returns_disabled_by_default
run_test_case "mud-config set enables feature" test_set_enables_feature
run_test_case "mud-config toggle flips state" test_toggle_flips_state
run_test_case "mud-config list shows all features" test_list_shows_all_features
run_test_case "mud-config set rejects invalid values" test_invalid_value_rejected

finish_tests
