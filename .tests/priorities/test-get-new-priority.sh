#!/bin/sh
# Test coverage for get-new-priority spell:
# - Shows usage with --help
# - Requires file argument
# - Fails on missing file

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/priorities/get-new-priority" --help
  assert_success || return 1
  assert_output_contains "Usage: get-new-priority" || return 1
}

test_requires_argument() {
  run_spell "spells/priorities/get-new-priority"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  run_spell "spells/priorities/get-new-priority" "/nonexistent/file.txt"
  assert_failure || return 1
  assert_error_contains "file not found" || return 1
}

test_returns_first_priority_when_none_exist() {
  tmpdir=$(make_tempdir)
  target="$tmpdir/target.txt"
  printf 'target\n' > "$target"

  run_spell "spells/priorities/get-new-priority" "$target"
  assert_success || return 1
  assert_output_contains "1 1" || return 1
}

test_returns_next_priority_in_highest_echelon() {
  tmpdir=$(make_tempdir)
  file1="$tmpdir/file1.txt"
  file2="$tmpdir/file2.txt"
  target="$tmpdir/target.txt"
  printf 'one\n' > "$file1"
  printf 'two\n' > "$file2"
  printf 'target\n' > "$target"

  run_spell "spells/priorities/prioritize" "$file1"
  if [ "$STATUS" -ne 0 ]; then
    export TEST_SKIP_REASON="xattr support not available"
    return 222
  fi
  run_spell "spells/priorities/prioritize" "$file2"
  assert_success || return 1

  run_spell "spells/priorities/get-new-priority" "$target"
  assert_success || return 1
  assert_output_contains "1 3" || return 1
}

test_uses_with_lock() {
  tmpdir=$(make_tempdir)
  target="$tmpdir/target.txt"
  lock_log="$tmpdir/with-lock.log"
  printf 'target\n' > "$target"

  cat >"$tmpdir/with-lock" <<'SH'
#!/bin/sh
printf '%s\n' "$1" > "$LOCK_LOG"
shift
"$@"
SH
  chmod +x "$tmpdir/with-lock"

  run_cmd env LOCK_LOG="$lock_log" PATH="$tmpdir:$PATH" \
    "$ROOT_DIR/spells/priorities/get-new-priority" "$target"
  assert_success || return 1
  assert_file_contains "$lock_log" ".wizardry-priorities.lock" || return 1
}

run_test_case "get-new-priority shows usage text" test_help
run_test_case "get-new-priority requires file argument" test_requires_argument
run_test_case "get-new-priority fails on missing file" test_fails_on_missing_file
run_test_case "get-new-priority returns 1 1 when empty" test_returns_first_priority_when_none_exist
run_test_case "get-new-priority returns next value in highest echelon" test_returns_next_priority_in_highest_echelon
run_test_case "get-new-priority uses with-lock" test_uses_with_lock


# Test via source-then-invoke pattern  

finish_tests
