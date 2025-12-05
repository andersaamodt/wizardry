#!/bin/sh
# Tests for the 'detect-indent-char' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
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


test_detect_space_indent() {
  tmpfile="$WIZARDRY_TMPDIR/space_indent.nix"
  printf '{\n  foo = true;\n  bar = 1;\n}\n' > "$tmpfile"
  run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-char" "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  case "$OUTPUT" in
    space*) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'space' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_detect_tab_indent() {
  tmpfile="$WIZARDRY_TMPDIR/tab_indent.nix"
  printf '{\n\tfoo = true;\n\tbar = 1;\n}\n' > "$tmpfile"
  run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-char" "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  case "$OUTPUT" in
    tab*) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'tab' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_detect_default_for_missing_file() {
  run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-char" "/nonexistent/file.nix"
  assert_success
  case "$OUTPUT" in
    space*) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'space' as default but got '$OUTPUT'"; return 1 ;;
  esac
}

test_detect_default_for_empty_file() {
  tmpfile="$WIZARDRY_TMPDIR/empty.nix"
  printf '' > "$tmpfile"
  run_cmd "$ROOT_DIR/spells/.imps/text/detect-indent-char" "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  case "$OUTPUT" in
    space*) return 0 ;;
    *) TEST_FAILURE_REASON="expected 'space' as default but got '$OUTPUT'"; return 1 ;;
  esac
}

run_test_case "detect-indent-char detects space indent" test_detect_space_indent
run_test_case "detect-indent-char detects tab indent" test_detect_tab_indent
run_test_case "detect-indent-char defaults to space for missing file" test_detect_default_for_missing_file
run_test_case "detect-indent-char defaults to space for empty file" test_detect_default_for_empty_file

finish_tests
