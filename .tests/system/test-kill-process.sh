#!/bin/sh
# Behavioral cases (derived from --help):
# - kill-process prints usage
# - kill-process requires ask_number
# - kill-process can kill a selected process using stubs
# - kill-process respects a refusal to terminate

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


test_help() {
  run_spell "spells/system/kill-process" --help
  assert_success || return 1
  assert_output_contains "Usage: kill-process" || return 1
}

kill_process_requires_ask_number() {
  tmpdir=$(make_tempdir)
  cat <<'STUB' >"$tmpdir/ps"
#!/bin/sh
cat <<'OUT'
  PID TTY      STAT   TIME COMMAND
123 ?        S      0:00 /usr/bin/foo
OUT
STUB
  chmod +x "$tmpdir/ps"

  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$tmpdir:/bin:/usr/bin" run_spell "spells/system/kill-process"
  assert_failure || return 1
  assert_error_contains "ask-number spell is required" || return 1
}

kill_process_requires_ask_yn() {
  tmpdir=$(make_tempdir)

  cat <<'STUB' >"$tmpdir/ps"
#!/bin/sh
cat <<'OUT'
COMMAND
foo
OUT
STUB
  cat <<'STUB' >"$tmpdir/ask-number"
#!/bin/sh
echo 1
STUB
  chmod +x "$tmpdir"/ps "$tmpdir"/ask-number

  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$tmpdir:/bin:/usr/bin" run_spell "spells/system/kill-process"
  assert_failure || return 1
  assert_error_contains "ask-yn spell is required" || return 1
}

kill_process_kills_selected_pid() {
  tmpdir=$(make_tempdir)

  cat <<'STUB' >"$tmpdir/ps"
#!/bin/sh
cat <<'OUT'
  PID TTY      STAT   TIME COMMAND
111 ?        S      0:00 /usr/bin/foo
222 ?        S      0:00 /usr/bin/bar
OUT
STUB
  cat <<'STUB' >"$tmpdir/ask-number"
#!/bin/sh
echo 2
STUB
  cat <<'STUB' >"$tmpdir/ask-yn"
#!/bin/sh
exit 0
STUB
  cat <<'STUB' >"$tmpdir/kill"
#!/bin/sh
printf '%s' "$*" >"${KILL_LOG:?}"
STUB
  chmod +x "$tmpdir"/ps "$tmpdir"/ask-number "$tmpdir"/ask-yn "$tmpdir/kill"

  kill_log="$tmpdir/kill.log"
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$tmpdir:/bin:/usr/bin" KILL_LOG="$kill_log" KILL_CMD="$tmpdir/kill" run_spell "spells/system/kill-process"
  assert_success || return 1
  assert_output_contains "Process 222" || return 1
  [ "$(cat "$kill_log")" = "222" ] || { TEST_FAILURE_REASON="kill command not called"; return 1; }
}

kill_process_handles_empty_process_list() {
  tmpdir=$(make_tempdir)

  cat <<'STUB' >"$tmpdir/ps"
#!/bin/sh
echo "COMMAND"
STUB
  cat <<'STUB' >"$tmpdir/ask-number"
#!/bin/sh
exit 1
STUB
  cat <<'STUB' >"$tmpdir/ask-yn"
#!/bin/sh
exit 1
STUB
  chmod +x "$tmpdir"/ps "$tmpdir"/ask-number "$tmpdir"/ask-yn

  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$tmpdir:/bin:/usr/bin" run_spell "spells/system/kill-process"
  assert_failure || return 1
  assert_error_contains "No processes available to kill." || return 1
}

kill_process_respects_refusal() {
  tmpdir=$(make_tempdir)

  cat <<'STUB' >"$tmpdir/ps"
#!/bin/sh
cat <<'OUT'
  PID TTY      STAT   TIME COMMAND
101 ?        S      0:00 first
202 ?        S      0:00 second
OUT
STUB
  cat <<'STUB' >"$tmpdir/ask-number"
#!/bin/sh
echo 1
STUB
  cat <<'STUB' >"$tmpdir/ask-yn"
#!/bin/sh
exit 1
STUB
  cat <<'STUB' >"$tmpdir/kill"
#!/bin/sh
printf '%s' "$*" >"${KILL_LOG:?}"
STUB
  chmod +x "$tmpdir"/ps "$tmpdir"/ask-number "$tmpdir"/ask-yn "$tmpdir/kill"

  kill_log="$tmpdir/kill.log"
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$tmpdir:/bin:/usr/bin" KILL_LOG="$kill_log" KILL_CMD="$tmpdir/kill" run_spell "spells/system/kill-process"
  assert_success || return 1
  case ${OUTPUT:-} in
    *"has been killed"*) TEST_FAILURE_REASON="process should not be reported killed"; return 1 ;;
  esac
  [ ! -s "$kill_log" ] || { TEST_FAILURE_REASON="kill command should not be invoked on refusal"; return 1; }
}

kill_process_requires_kill_command() {
  tmpdir=$(make_tempdir)

  cat <<'STUB' >"$tmpdir/ps"
#!/bin/sh
cat <<'OUT'
  PID TTY      STAT   TIME COMMAND
101 ?        S      0:00 first
OUT
STUB
  cat <<'STUB' >"$tmpdir/ask-number"
#!/bin/sh
echo 1
STUB
  cat <<'STUB' >"$tmpdir/ask-yn"
#!/bin/sh
exit 0
STUB
  chmod +x "$tmpdir"/ps "$tmpdir"/ask-number "$tmpdir"/ask-yn

  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$tmpdir:/bin:/usr/bin" KILL_CMD="$tmpdir/not-here" run_spell "spells/system/kill-process"
  assert_failure || return 1
  assert_error_contains "kill command" || return 1
  assert_error_contains "not-here" || return 1
}

kill_process_reports_failed_kill() {
  tmpdir=$(make_tempdir)

  cat <<'STUB' >"$tmpdir/ps"
#!/bin/sh
cat <<'OUT'
  PID TTY      STAT   TIME COMMAND
303 ?        S      0:00 third
OUT
STUB
  cat <<'STUB' >"$tmpdir/ask-number"
#!/bin/sh
echo 1
STUB
  cat <<'STUB' >"$tmpdir/ask-yn"
#!/bin/sh
exit 0
STUB
  cat <<'STUB' >"$tmpdir/kill"
#!/bin/sh
echo "operation not permitted" >&2
exit 1
STUB
  chmod +x "$tmpdir"/ps "$tmpdir"/ask-number "$tmpdir"/ask-yn "$tmpdir/kill"

  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$tmpdir:/bin:/usr/bin" KILL_CMD="$tmpdir/kill" run_spell "spells/system/kill-process"
  assert_failure || return 1
  assert_error_contains "Failed to kill process 303" || return 1
  case ${OUTPUT:-} in
    *"has been killed"*) TEST_FAILURE_REASON="success message should not be printed on failure"; return 1 ;;
  esac
}

run_test_case "kill-process prints usage" test_help
run_test_case "kill-process requires ask_number" kill_process_requires_ask_number
run_test_case "kill-process requires ask_yn" kill_process_requires_ask_yn
run_test_case "kill-process can terminate the chosen process" kill_process_kills_selected_pid
run_test_case "kill-process exits when no processes exist" kill_process_handles_empty_process_list
run_test_case "kill-process skips termination when declined" kill_process_respects_refusal
run_test_case "kill-process validates kill command presence" kill_process_requires_kill_command
run_test_case "kill-process reports kill failures" kill_process_reports_failed_kill

finish_tests
