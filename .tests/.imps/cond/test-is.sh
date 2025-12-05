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
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  _run_spell spells/.imps/cond/is file "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
}

test_is_file_fails_for_dir() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  _run_spell spells/.imps/cond/is file "$tmpdir"
  rmdir "$tmpdir"
  _assert_failure
}

test_is_dir() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  _run_spell spells/.imps/cond/is dir "$tmpdir"
  rmdir "$tmpdir"
  _assert_success
}

test_is_dir_fails_for_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  _run_spell spells/.imps/cond/is dir "$tmpfile"
  rm -f "$tmpfile"
  _assert_failure
}

test_is_exec() {
  _run_spell spells/.imps/cond/is exec /bin/sh
  _assert_success
}

test_is_set() {
  _run_spell spells/.imps/cond/is set "nonempty"
  _assert_success
}

test_is_set_fails_for_empty() {
  _run_spell spells/.imps/cond/is set ""
  _assert_failure
}

test_is_unset() {
  _run_spell spells/.imps/cond/is unset ""
  _assert_success
}

test_is_empty_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  _run_spell spells/.imps/cond/is empty "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
}

test_is_empty_fails_for_nonempty_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'content' > "$tmpfile"
  _run_spell spells/.imps/cond/is empty "$tmpfile"
  rm -f "$tmpfile"
  _assert_failure
}

# Additional tests for better coverage
test_is_link() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  tmplink="$WIZARDRY_TMPDIR/testlink_$$"
  ln -s "$tmpfile" "$tmplink"
  _run_spell spells/.imps/cond/is link "$tmplink"
  rm -f "$tmplink" "$tmpfile"
  _assert_success
}

test_is_link_fails_for_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  _run_spell spells/.imps/cond/is link "$tmpfile"
  rm -f "$tmpfile"
  _assert_failure
}

test_is_readable() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  _run_spell spells/.imps/cond/is readable "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
}

test_is_writable() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  _run_spell spells/.imps/cond/is writable "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
}

test_is_empty_dir() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  _run_spell spells/.imps/cond/is empty "$tmpdir"
  rmdir "$tmpdir"
  _assert_success
}

test_is_empty_dir_fails_when_not_empty() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/testdir.XXXXXX")
  touch "$tmpdir/file"
  _run_spell spells/.imps/cond/is empty "$tmpdir"
  rm -rf "$tmpdir"
  _assert_failure
}

test_is_exec_fails_for_nonexec() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  chmod -x "$tmpfile"
  _run_spell spells/.imps/cond/is exec "$tmpfile"
  rm -f "$tmpfile"
  _assert_failure
}

test_is_unset_fails_for_nonempty() {
  _run_spell spells/.imps/cond/is unset "value"
  _assert_failure
}

test_is_unknown_type_fails() {
  _run_spell spells/.imps/cond/is unknowntype "/tmp"
  _assert_failure
}

_run_test_case "is file succeeds for file" test_is_file
_run_test_case "is file fails for directory" test_is_file_fails_for_dir
_run_test_case "is dir succeeds for directory" test_is_dir
_run_test_case "is dir fails for file" test_is_dir_fails_for_file
_run_test_case "is exec succeeds for executable" test_is_exec
_run_test_case "is exec fails for non-executable" test_is_exec_fails_for_nonexec
_run_test_case "is set succeeds for non-empty" test_is_set
_run_test_case "is set fails for empty" test_is_set_fails_for_empty
_run_test_case "is unset succeeds for empty" test_is_unset
_run_test_case "is unset fails for non-empty" test_is_unset_fails_for_nonempty
_run_test_case "is empty succeeds for empty file" test_is_empty_file
_run_test_case "is empty fails for non-empty file" test_is_empty_fails_for_nonempty_file
_run_test_case "is empty succeeds for empty dir" test_is_empty_dir
_run_test_case "is empty fails for non-empty dir" test_is_empty_dir_fails_when_not_empty
_run_test_case "is link succeeds for symlink" test_is_link
_run_test_case "is link fails for regular file" test_is_link_fails_for_file
_run_test_case "is readable succeeds" test_is_readable
_run_test_case "is writable succeeds" test_is_writable
_run_test_case "is unknown type fails" test_is_unknown_type_fails

_finish_tests
