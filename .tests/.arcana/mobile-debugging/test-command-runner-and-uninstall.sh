#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

termux_runner_requires_its_envelope() {
  run_cmd sh "$ROOT_DIR/spells/.arcana/mobile-debugging/termux-command-runner"
  assert_status 2
}

termux_runner_shows_help() {
  run_spell spells/.arcana/mobile-debugging/termux-command-runner --help
  assert_success || return 1
  assert_output_contains "Usage: termux-command-runner"
}

termux_runner_records_complete_receipts() {
  runner=$ROOT_DIR/spells/.arcana/mobile-debugging/termux-command-runner
  grep -q 'stdout.txt' "$runner" &&
    grep -q 'stderr.txt' "$runner" &&
    grep -q 'exit-code.txt' "$runner"
}

termux_runner_holds_wake_lock_for_payload() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/results" "$tmpdir/work"
  : >"$tmpdir/args.txt"

  cat >"$tmpdir/wake-lock" <<'SH'
#!/bin/sh
printf 'lock\n' >>"$WAKE_LOG"
SH
  cat >"$tmpdir/wake-unlock" <<'SH'
#!/bin/sh
printf 'unlock\n' >>"$WAKE_LOG"
SH
  cat >"$tmpdir/payload.sh" <<'SH'
#!/bin/sh
printf 'payload stdout\n'
printf 'payload stderr\n' >&2
exit 7
SH
  chmod +x "$tmpdir/wake-lock" "$tmpdir/wake-unlock" "$tmpdir/payload.sh"

  WAKE_LOG="$tmpdir/wake.log" \
    TERMUX_SHELL_COMMAND=/bin/sh \
    TERMUX_WAKE_LOCK_COMMAND="$tmpdir/wake-lock" \
    TERMUX_WAKE_UNLOCK_COMMAND="$tmpdir/wake-unlock" \
    run_cmd sh "$ROOT_DIR/spells/.arcana/mobile-debugging/termux-command-runner" \
      "$tmpdir/payload.sh" "$tmpdir/results" "$tmpdir/args.txt" "$tmpdir/work"

  assert_success || return 1
  assert_file_contains "$tmpdir/wake.log" "lock" || return 1
  assert_file_contains "$tmpdir/wake.log" "unlock" || return 1
  assert_file_contains "$tmpdir/results/stdout.txt" "payload stdout" || return 1
  assert_file_contains "$tmpdir/results/stderr.txt" "payload stderr" || return 1
  assert_file_contains "$tmpdir/results/exit-code.txt" "7"
}

android_commandline_uninstaller_shows_help() {
  run_spell spells/.arcana/mobile-debugging/uninstall-android-commandline-tools --help
  assert_success
}

run_test_case "Termux command runner requires its job envelope" termux_runner_requires_its_envelope
run_test_case "Termux command runner shows help" termux_runner_shows_help
run_test_case "Termux command runner records complete receipts" termux_runner_records_complete_receipts
run_test_case "Termux command runner holds a wake lock for each payload" \
  termux_runner_holds_wake_lock_for_payload
run_test_case "Android command-line tools uninstaller shows help" android_commandline_uninstaller_shows_help
finish_tests
