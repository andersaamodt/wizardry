#!/bin/sh
# Behavioral cases (derived from --help):
# - move-cursor enforces argument count
# - move-cursor validates numeric coordinates
# - move-cursor clamps coordinates and emits escape
# - move-cursor is a no-op on dumb terminals

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


move_cursor_requires_two_arguments() {
  run_spell "spells/cantrips/move-cursor" 5
  assert_failure || return 1
  assert_error_contains "Usage: move-cursor" || return 1
}

move_cursor_rejects_non_numeric_coordinates() {
  run_spell "spells/cantrips/move-cursor" abc 2
  assert_failure || return 1
  assert_error_contains "invalid column" || return 1

  run_spell "spells/cantrips/move-cursor" 3 two
  assert_failure || return 1
  assert_error_contains "invalid row" || return 1
}

move_cursor_clamps_and_emits_escape_sequence() {
  run_cmd env TERM=xterm "$ROOT_DIR/spells/cantrips/move-cursor" 0 0
  assert_success || return 1
  expected=$(printf '\033[1;1H')
  [ "$OUTPUT" = "$expected" ] || { TEST_FAILURE_REASON="expected escape to row 1 col 1"; return 1; }
}

move_cursor_succeeds_quietly_on_dumb_terminal() {
  run_cmd env TERM=dumb "$ROOT_DIR/spells/cantrips/move-cursor" 4 7
  assert_success || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no output on dumb terminal"; return 1; }
}

run_test_case "move-cursor enforces argument count" move_cursor_requires_two_arguments
run_test_case "move-cursor validates numeric coordinates" move_cursor_rejects_non_numeric_coordinates
run_test_case "move-cursor clamps coordinates and emits escape" move_cursor_clamps_and_emits_escape_sequence
run_test_case "move-cursor is a no-op on dumb terminals" move_cursor_succeeds_quietly_on_dumb_terminal

shows_help() {
  run_spell spells/cantrips/move-cursor --help
  # Help is printed via usage function (returns non-zero, output to stderr)
  assert_error_contains "Usage:"
}

run_test_case "move-cursor shows help" shows_help

finish_tests
