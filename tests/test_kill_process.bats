#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
  stub_dir="$BATS_TEST_TMPDIR/ps_stub"
  mkdir -p "$stub_dir"
  cat <<'PS' >"$stub_dir/ps"
#!/usr/bin/env bash
if [ "$1" = "-ax" ]; then
  cat <<'OUT'
  PID TTY      STAT   TIME COMMAND
 101 ?        S      0:00 first
 202 ?        S      0:00 second
OUT
else
  /bin/ps "$@"
fi
PS
  chmod +x "$stub_dir/ps"

  kill_log="$BATS_TEST_TMPDIR/kill.log"
  cat <<'KILL' >"$stub_dir/kill"
#!/usr/bin/env bash
  printf 'kill %s\n' "$*" >>"${KILL_LOG}" 2>/dev/null || true
exit 0
KILL
  chmod +x "$stub_dir/kill"

  system_stubs=$(wizardry_install_systemd_stubs)
  export KILL_CMD="$stub_dir/kill"
}

teardown() {
  unset KILL_CMD
  PATH=$ORIGINAL_PATH
  default_teardown
}

with_stubs() {
  PATH="$(wizardry_join_paths "$stub_dir" "$system_stubs" "$ORIGINAL_PATH")" "$@"
}

@test 'kill-process terminates selected process when confirmed' {
  printf '2\n' >"$BATS_TEST_TMPDIR/choice"
  : >"$kill_log"
  export KILL_LOG="$kill_log"
  export ASK_YN_STUB_RESPONSE=Y
  ASK_CANTRIP_INPUT=stdin with_stubs run_spell 'spells/kill-process' <"$BATS_TEST_TMPDIR/choice"
  unset ASK_YN_STUB_RESPONSE
  assert_success
  assert_output --partial 'List of running processes:'
  assert_output --partial 'Process 202 (second) has been killed.'
  run cat "$kill_log"
  assert_success
  assert_output 'kill 202'
}

@test 'kill-process respects refusal to terminate process' {
  printf '' >"$kill_log"
  printf '1\n' >"$BATS_TEST_TMPDIR/choice_no"
  export KILL_LOG="$kill_log"
  export ASK_YN_STUB_RESPONSE=n
  ASK_CANTRIP_INPUT=stdin with_stubs run_spell 'spells/kill-process' <"$BATS_TEST_TMPDIR/choice_no"
  unset ASK_YN_STUB_RESPONSE
  assert_success
  [[ "$output" != *'has been killed'* ]]
  run cat "$kill_log"
  assert_success
  assert_output ''
}

