#!/bin/sh
# Tests for the 'sed-inplace' imp

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


test_sed_inplace_substitutes() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'hello world' > "$tmpfile"
  run_spell spells/.imps/fs/sed-inplace 's/world/universe/' "$tmpfile"
  assert_success
  content=$(cat "$tmpfile")
  [ "$content" = "hello universe" ] || { TEST_FAILURE_REASON="expected 'hello universe' got '$content'"; return 1; }
  rm -f "$tmpfile"
}

test_sed_inplace_global() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'foo foo foo' > "$tmpfile"
  run_spell spells/.imps/fs/sed-inplace 's/foo/bar/g' "$tmpfile"
  assert_success
  content=$(cat "$tmpfile")
  [ "$content" = "bar bar bar" ] || { TEST_FAILURE_REASON="expected 'bar bar bar' got '$content'"; return 1; }
  rm -f "$tmpfile"
}

test_sed_inplace_missing_file_fails() {
  run_spell spells/.imps/fs/sed-inplace 's/a/b/' "/nonexistent/file"
  assert_failure
}

test_sed_inplace_no_pattern_fails() {
  run_spell spells/.imps/fs/sed-inplace
  assert_failure
}

test_sed_inplace_no_file_fails() {
  run_spell spells/.imps/fs/sed-inplace 's/a/b/'
  assert_failure
}

test_sed_inplace_directory_fails() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  run_spell spells/.imps/fs/sed-inplace 's/a/b/' "$tmpdir"
  rmdir "$tmpdir"
  assert_failure
}

run_test_case "sed-inplace substitutes text" test_sed_inplace_substitutes
run_test_case "sed-inplace global flag" test_sed_inplace_global
run_test_case "sed-inplace missing file fails" test_sed_inplace_missing_file_fails
run_test_case "sed-inplace no pattern fails" test_sed_inplace_no_pattern_fails
run_test_case "sed-inplace no file fails" test_sed_inplace_no_file_fails
run_test_case "sed-inplace directory fails" test_sed_inplace_directory_fails

finish_tests
