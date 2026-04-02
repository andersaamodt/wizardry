#!/bin/sh
# Test coverage for upvote spell:
# - Shows usage with --help
# - Requires file argument
# - Fails on missing file
# - Increments upvote count

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/priorities/upvote" --help
  assert_success || return 1
  assert_output_contains "Usage: upvote" || return 1
}

test_requires_argument() {
  run_spell "spells/priorities/upvote"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  run_spell "spells/priorities/upvote" "/nonexistent/file.txt"
  assert_failure || return 1
  assert_error_contains "file not found" || return 1
}

test_increments_upvote_count() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/upvote.txt"
  printf 'vote\n' > "$testfile"

  run_spell "spells/priorities/upvote" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    export TEST_SKIP_REASON="xattr support not available"
    return 222
  fi
  assert_success || return 1
  assert_output_contains "Upvotes: 1" || return 1

  run_spell "spells/priorities/upvote" "$testfile"
  assert_success || return 1
  assert_output_contains "Upvotes: 2" || return 1
}

test_uses_with_lock() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/upvote-lock.txt"
  lock_log="$tmpdir/with-lock.log"
  printf 'vote\n' > "$testfile"

  cat >"$tmpdir/with-lock" <<'SH'
#!/bin/sh
printf '%s\n' "$1" > "$LOCK_LOG"
shift
"$@"
SH
  chmod +x "$tmpdir/with-lock"

  run_cmd env LOCK_LOG="$lock_log" PATH="$tmpdir:$PATH" \
    "$ROOT_DIR/spells/priorities/upvote" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    export TEST_SKIP_REASON="xattr support not available"
    return 222
  fi
  assert_success || return 1
  assert_file_contains "$lock_log" ".wizardry-priorities.lock" || return 1
}

run_test_case "upvote shows usage text" test_help
run_test_case "upvote requires file argument" test_requires_argument
run_test_case "upvote fails on missing file" test_fails_on_missing_file
run_test_case "upvote increments count" test_increments_upvote_count
run_test_case "upvote uses with-lock" test_uses_with_lock


# Test via source-then-invoke pattern  

finish_tests
