#!/bin/sh
# Tests for the 'is' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_is_file() {
  skip-if-compiled || return $?
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/cond/is file "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

test_is_file_fails_for_dir() {
  skip-if-compiled || return $?
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  run_spell spells/.imps/cond/is file "$tmpdir"
  rmdir "$tmpdir"
  assert_failure
}

test_is_dir() {
  skip-if-compiled || return $?
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  run_spell spells/.imps/cond/is dir "$tmpdir"
  rmdir "$tmpdir"
  assert_success
}

test_is_dir_fails_for_file() {
  skip-if-compiled || return $?
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  run_spell spells/.imps/cond/is dir "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

test_is_exec() {
  skip-if-compiled || return $?
  run_spell spells/.imps/cond/is exec /bin/sh
  assert_success
}

test_is_set() {
  skip-if-compiled || return $?
  run_spell spells/.imps/cond/is set "nonempty"
  assert_success
}

test_is_set_fails_for_empty() {
  skip-if-compiled || return $?
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
  skip-if-compiled || return $?
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
  skip-if-compiled || return $?
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
  skip-if-compiled || return $?
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  touch "$tmpdir/file"
  run_spell spells/.imps/cond/is empty "$tmpdir"
  rm -rf "$tmpdir"
  assert_failure
}

test_is_exec_fails_for_nonexec() {
  skip-if-compiled || return $?
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  chmod -x "$tmpfile"
  run_spell spells/.imps/cond/is exec "$tmpfile"
  rm -f "$tmpfile"
  assert_failure
}

test_is_unset_fails_for_nonempty() {
  skip-if-compiled || return $?
  run_spell spells/.imps/cond/is unset "value"
  assert_failure
}

test_is_unknown_type_fails() {
  skip-if-compiled || return $?
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
