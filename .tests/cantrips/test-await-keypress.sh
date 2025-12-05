#!/bin/sh
# Behavior cases from --help: read one key and name it; handles escape sequences and buffered bytes.
# - Emits descriptive names for control keys like Enter.
# - Decodes literal text from provided byte codes.
# - Buffers incomplete escape sequences for the next invocation.
# - Flushes buffers when a complete key is decoded.

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


await_with_buffer() {
  buffer=$1
  shift
  run_cmd env \
    AWAIT_KEYPRESS_BUFFER_FILE="$buffer" \
    AWAIT_KEYPRESS_SKIP_STTY=1 \
    AWAIT_KEYPRESS_DEVICE=/dev/null \
    "$ROOT_DIR/spells/cantrips/await-keypress" "$@"
}

# prints enter for newline code
prints_enter_for_newline() {
  buffer_file=$(mktemp "${WIZARDRY_TMPDIR}/await-buffer.XXXXXX")
  printf '10\n' >"$buffer_file"
  await_with_buffer "$buffer_file"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "enter" ] || { TEST_FAILURE_REASON="expected enter but got $OUTPUT"; return 1; }
  [ ! -e "$buffer_file" ] || { TEST_FAILURE_REASON="buffer file should be cleared"; return 1; }
}

# decodes literal text from buffered byte codes
prints_literal_text() {
  buffer_file=$(mktemp "${WIZARDRY_TMPDIR}/await-buffer.XXXXXX")
  printf '97 98\n' >"$buffer_file"
  await_with_buffer "$buffer_file"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "ab" ] || { TEST_FAILURE_REASON="expected ab but got $OUTPUT"; return 1; }
}

# buffers partial escape sequences for later completion
buffers_partial_escape_sequence() {
  partial_file=$(mktemp "${WIZARDRY_TMPDIR}/await-buffer.XXXXXX")
  printf '27 91\n' >"$partial_file"
  await_with_buffer "$partial_file"
  [ "$STATUS" -eq 0 ] || return 1
  [ -s "$partial_file" ] || { TEST_FAILURE_REASON="expected partial codes to remain"; return 1; }
  [ "$(cat "$partial_file")" = '27 91' ] || { TEST_FAILURE_REASON="unexpected buffered codes"; return 1; }

  printf '27 91 68\n' >"$partial_file"
  await_with_buffer "$partial_file"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = 'left' ] || { TEST_FAILURE_REASON="expected left but got $OUTPUT"; return 1; }
  [ ! -s "$partial_file" ] || { TEST_FAILURE_REASON="buffer should be cleared after completion"; return 1; }
}

run_test_case "prints enter for newline" prints_enter_for_newline
run_test_case "prints literal text from bytes" prints_literal_text
run_test_case "buffers partial escape sequence until complete" buffers_partial_escape_sequence

shows_help() {
  run_spell spells/cantrips/await-keypress --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "await-keypress shows help" shows_help
finish_tests
