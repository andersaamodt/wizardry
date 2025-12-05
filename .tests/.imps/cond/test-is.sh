#!/bin/sh
# Tests for the 'is' imp

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


test_is_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/cond/is file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_is_file_fails_for_dir() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  run_spell spells/.imps/cond/is file "$tmpdir"
  rmdir "$tmpdir"
  assert_failure
}

test_is_dir() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  run_spell spells/.imps/cond/is dir "$tmpdir"
  rmdir "$tmpdir"
  assert_success
}

test_is_dir_fails_for_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/cond/is dir "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

test_is_exec() {
  run_spell spells/.imps/cond/is exec /bin/sh
  assert_success
}

test_is_set() {
  run_spell spells/.imps/cond/is set "nonempty"
  assert_success
}

test_is_set_fails_for_empty() {
  run_spell spells/.imps/cond/is set ""
  assert_failure
}

test_is_unset() {
  run_spell spells/.imps/cond/is unset ""
  assert_success
}

test_is_empty_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/cond/is empty "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_is_empty_fails_for_nonempty_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'content' > "$tmpfile"
  run_spell spells/.imps/cond/is empty "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

# Additional tests for better coverage
test_is_link() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  tmplink="$WIZARDRY_TMPDIR/testlink_$$"
  ln -s "$tmpfile" "$tmplink"
  run_spell spells/.imps/cond/is link "$tmplink"
  rm -f "$tmplink" "$tmpfile"
  assert_success
}

test_is_link_fails_for_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/cond/is link "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

test_is_readable() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/cond/is readable "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_is_writable() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/cond/is writable "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_is_empty_dir() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  run_spell spells/.imps/cond/is empty "$tmpdir"
  rmdir "$tmpdir"
  assert_success
}

test_is_empty_dir_fails_when_not_empty() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  touch "$tmpdir/file"
  run_spell spells/.imps/cond/is empty "$tmpdir"
  rm -rf "$tmpdir"
  assert_failure
}

test_is_exec_fails_for_nonexec() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  chmod -x "$tmpfile"
  run_spell spells/.imps/cond/is exec "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

test_is_unset_fails_for_nonempty() {
  run_spell spells/.imps/cond/is unset "value"
  assert_failure
}

test_is_unknown_type_fails() {
  run_spell spells/.imps/cond/is unknowntype "/tmp"
  assert_failure
}

run_test_case "is file succeeds for file" test_is_file
run_test_case "is file fails for directory" test_is_file_fails_for_dir
run_test_case "is dir succeeds for directory" test_is_dir
run_test_case "is dir fails for file" test_is_dir_fails_for_file
run_test_case "is exec succeeds for executable" test_is_exec
run_test_case "is exec fails for non-executable" test_is_exec_fails_for_nonexec
run_test_case "is set succeeds for non-empty" test_is_set
run_test_case "is set fails for empty" test_is_set_fails_for_empty
run_test_case "is unset succeeds for empty" test_is_unset
run_test_case "is unset fails for non-empty" test_is_unset_fails_for_nonempty
run_test_case "is empty succeeds for empty file" test_is_empty_file
run_test_case "is empty fails for non-empty file" test_is_empty_fails_for_nonempty_file
run_test_case "is empty succeeds for empty dir" test_is_empty_dir
run_test_case "is empty fails for non-empty dir" test_is_empty_dir_fails_when_not_empty
run_test_case "is link succeeds for symlink" test_is_link
run_test_case "is link fails for regular file" test_is_link_fails_for_file
run_test_case "is readable succeeds" test_is_readable
run_test_case "is writable succeeds" test_is_writable
run_test_case "is unknown type fails" test_is_unknown_type_fails

finish_tests
