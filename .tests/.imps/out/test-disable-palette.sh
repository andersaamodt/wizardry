#!/bin/sh
# Tests for the 'disable-palette' imp

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


test_disable_palette_clears_colors() {
  # Source colors first, then disable-palette, then check that variables are empty
  run_cmd sh -c ". '$ROOT_DIR/spells/cantrips/colors'; . '$ROOT_DIR/spells/.imps/out/disable-palette'; printf '%s' \"\$RESET\""
  assert_success
  # RESET should be empty after disable-palette
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="RESET should be empty but got: $OUTPUT"; return 1; }
}

test_disable_palette_clears_theme_colors() {
  run_cmd sh -c ". '$ROOT_DIR/spells/cantrips/colors'; . '$ROOT_DIR/spells/.imps/out/disable-palette'; printf '%s' \"\$THEME_HIGHLIGHT\""
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="THEME_HIGHLIGHT should be empty but got: $OUTPUT"; return 1; }
}

test_disable_palette_clears_mud_colors() {
  run_cmd sh -c ". '$ROOT_DIR/spells/cantrips/colors'; . '$ROOT_DIR/spells/.imps/out/disable-palette'; printf '%s' \"\$MUD_LOCATION\""
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="MUD_LOCATION should be empty but got: $OUTPUT"; return 1; }
}

test_disable_palette_sets_flag() {
  run_cmd sh -c ". '$ROOT_DIR/spells/cantrips/colors'; . '$ROOT_DIR/spells/.imps/out/disable-palette'; printf '%s' \"\$WIZARDRY_COLORS_AVAILABLE\""
  assert_success
  [ "$OUTPUT" = "0" ] || { TEST_FAILURE_REASON="WIZARDRY_COLORS_AVAILABLE should be 0 but got: $OUTPUT"; return 1; }
}

test_disable_palette_multiple_colors_empty() {
  # Check that multiple color variables are all set to empty
  run_cmd sh -c ". '$ROOT_DIR/spells/cantrips/colors'; . '$ROOT_DIR/spells/.imps/out/disable-palette'; printf '%s|%s|%s|%s' \"\$RED\" \"\$GREEN\" \"\$BLUE\" \"\$CYAN\""
  assert_success
  [ "$OUTPUT" = "|||" ] || { TEST_FAILURE_REASON="Color variables should all be empty but got: $OUTPUT"; return 1; }
}

run_test_case "disable-palette clears RESET color" test_disable_palette_clears_colors
run_test_case "disable-palette clears theme colors" test_disable_palette_clears_theme_colors
run_test_case "disable-palette clears MUD colors" test_disable_palette_clears_mud_colors
run_test_case "disable-palette sets WIZARDRY_COLORS_AVAILABLE=0" test_disable_palette_sets_flag
run_test_case "disable-palette clears multiple colors" test_disable_palette_multiple_colors_empty

finish_tests
