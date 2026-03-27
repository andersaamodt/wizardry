#!/bin/sh
# Tests for the 'with-lock' imp

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_requires_arguments() {
  skip-if-compiled || return $?
  run_spell "spells/.imps/fs/with-lock"
  assert_failure || return 1
  assert_error_contains "usage: with-lock LOCK_FILE COMMAND" || return 1
}

test_uses_flock_when_available() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  log_file="$tmpdir/flock.log"
  lock_file="$tmpdir/test.lock"

  cat >"$tmpdir/flock" <<'SH'
#!/bin/sh
printf '%s\n' "$1" > "$LOCK_LOG"
shift
"$@"
SH
  chmod +x "$tmpdir/flock"

  run_cmd env LOCK_LOG="$log_file" PATH="$tmpdir:/bin" \
    "$ROOT_DIR/spells/.imps/fs/with-lock" "$lock_file" sh -c 'printf "ok\n"'
  assert_success || return 1
  assert_output_contains "ok" || return 1
  assert_file_contains "$log_file" "$lock_file" || return 1
}

test_falls_back_to_lockf() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  log_file="$tmpdir/lockf.log"
  lock_file="$tmpdir/test.lock"

  cat >"$tmpdir/lockf" <<'SH'
#!/bin/sh
printf '%s\n' "$1" > "$LOCK_LOG"
shift
"$@"
SH
  chmod +x "$tmpdir/lockf"

  run_cmd env LOCK_LOG="$log_file" PATH="$tmpdir:/bin" \
    "$ROOT_DIR/spells/.imps/fs/with-lock" "$lock_file" sh -c 'printf "ok\n"'
  assert_success || return 1
  assert_output_contains "ok" || return 1
  assert_file_contains "$log_file" "$lock_file" || return 1
}

test_fails_without_lock_tool() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  lock_file="$tmpdir/test.lock"

  cat >"$tmpdir/ok" <<'SH'
#!/bin/sh
printf '%s\n' "ok"
SH
  chmod +x "$tmpdir/ok"

  run_cmd env PATH="$tmpdir" "$ROOT_DIR/spells/.imps/fs/with-lock" "$lock_file" ok
  assert_failure || return 1
  assert_error_contains "no lock tool available" || return 1
}

run_test_case "with-lock requires arguments" test_requires_arguments
run_test_case "with-lock uses flock when available" test_uses_flock_when_available
run_test_case "with-lock falls back to lockf" test_falls_back_to_lockf
run_test_case "with-lock fails when no lock tool exists" test_fails_without_lock_tool

finish_tests
