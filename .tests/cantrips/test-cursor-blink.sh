#!/bin/sh
# Behavioral cases (derived from --help):
# - cursor-blink enforces argument count
# - cursor-blink rejects unknown states
# - cursor-blink is a no-op on dumb terminals
# - cursor-blink prints ANSI codes for supported terminals

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


cursor_blink_requires_one_argument() {
  run_spell "spells/cantrips/cursor-blink"
  assert_failure || return 1
  assert_error_contains "Usage: cursor-blink" || return 1
}

cursor_blink_handles_unknown_value() {
  run_cmd env TERM=xterm "$ROOT_DIR/spells/cantrips/cursor-blink" maybe
  assert_failure || return 1
  assert_error_contains "Usage: cursor-blink" || return 1
}

cursor_blink_succeeds_silently_on_dumb_terminal() {
  run_cmd env TERM=dumb "$ROOT_DIR/spells/cantrips/cursor-blink" on
  assert_success || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no output on dumb terminal"; return 1; }
}

cursor_blink_emits_escape_sequences() {
  run_cmd env TERM=xterm "$ROOT_DIR/spells/cantrips/cursor-blink" on
  assert_success || return 1
  expected_on=$(printf '\033[?25h')
  [ "$OUTPUT" = "$expected_on" ] || { TEST_FAILURE_REASON="unexpected output for on"; return 1; }

  run_cmd env TERM=xterm "$ROOT_DIR/spells/cantrips/cursor-blink" off
  assert_success || return 1
  expected_off=$(printf '\033[?25l')
  [ "$OUTPUT" = "$expected_off" ] || { TEST_FAILURE_REASON="unexpected output for off"; return 1; }
}

run_test_case "cursor-blink enforces argument count" cursor_blink_requires_one_argument
run_test_case "cursor-blink rejects unknown states" cursor_blink_handles_unknown_value
run_test_case "cursor-blink is a no-op on dumb terminals" cursor_blink_succeeds_silently_on_dumb_terminal
run_test_case "cursor-blink prints ANSI codes for supported terminals" cursor_blink_emits_escape_sequences

shows_help() {
  # Set TERM to ensure cursor-blink doesn't exit early on "dumb" terminals
  run_cmd env TERM=xterm "$ROOT_DIR/spells/cantrips/cursor-blink" --help
  # Help is printed via usage function (returns non-zero, output to stderr)
  # Check both stdout and stderr for the usage message
  combined="$OUTPUT$ERROR"
  case "$combined" in
    *cursor-blink*) return 0 ;;
    *Usage*) return 0 ;;
    *) TEST_FAILURE_REASON="help output missing Usage"; return 1 ;;
  esac
}

run_test_case "cursor-blink shows help" shows_help

finish_tests
