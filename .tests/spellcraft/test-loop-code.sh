#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

make_opencode_stub() {
  moc_stub_dir=$1
  mkdir -p "$moc_stub_dir"
  cat >"$moc_stub_dir/opencode" <<'SH'
#!/bin/sh
if [ "${1-}" = "db" ]; then
  printf '%s\n' "${OPENCODE_TEST_SESSION_ID:-ses_test_loop_code}"
  exit 0
fi

printf '%s\n' "$*" >>"$OPENCODE_TEST_LOG"
count=0
[ ! -f "$OPENCODE_TEST_COUNT" ] || count=$(cat "$OPENCODE_TEST_COUNT")
count=$((count + 1))
printf '%s\n' "$count" >"$OPENCODE_TEST_COUNT"

if [ "$count" -eq 1 ] && [ -n "${OPENCODE_TEST_REWRITE_CONFIG:-}" ]; then
  cat >"$OPENCODE_TEST_REWRITE_CONFIG" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "github-copilot/gpt-5.2"
}
EOF
fi

printf 'OpenCode test output for round %s\n' "$count"
case ${OPENCODE_TEST_MODE:-complete-second} in
  complete-second)
    if [ "$count" -ge 2 ]; then
      sed 's/\[ \]/[x]/g' "$OPENCODE_TEST_CHECKLIST" >"$OPENCODE_TEST_CHECKLIST.next"
      mv "$OPENCODE_TEST_CHECKLIST.next" "$OPENCODE_TEST_CHECKLIST"
      printf '%s\n' 'WIZARDRY_CHECKLIST_COMPLETE'
    fi
    ;;
  false-complete)
    if [ "$count" -eq 1 ]; then
      printf '%s\n' 'WIZARDRY_CHECKLIST_COMPLETE'
    else
      sed 's/\[ \]/[x]/g' "$OPENCODE_TEST_CHECKLIST" >"$OPENCODE_TEST_CHECKLIST.next"
      mv "$OPENCODE_TEST_CHECKLIST.next" "$OPENCODE_TEST_CHECKLIST"
      printf '%s\n' 'WIZARDRY_CHECKLIST_COMPLETE'
    fi
    ;;
  direction)
    printf '%s\n' 'WIZARDRY_CHECKLIST_NEEDS_DIRECTION: Which production signing identity should be used?'
    ;;
  balk)
    if [ "$count" -eq 1 ]; then
      printf '%s\n' 'WIZARDRY_CHECKLIST_NEEDS_DIRECTION: Completing all remaining items requires broad architectural decisions and running-app verification'
    else
      sed 's/\[ \]/[x]/g' "$OPENCODE_TEST_CHECKLIST" >"$OPENCODE_TEST_CHECKLIST.next"
      mv "$OPENCODE_TEST_CHECKLIST.next" "$OPENCODE_TEST_CHECKLIST"
      printf '%s\n' 'WIZARDRY_CHECKLIST_COMPLETE'
    fi
    ;;
  cancel-after-progress)
    if [ "$count" -eq 1 ]; then
      sed '1s/\[ \]/[x]/' "$OPENCODE_TEST_CHECKLIST" >"$OPENCODE_TEST_CHECKLIST.next"
      mv "$OPENCODE_TEST_CHECKLIST.next" "$OPENCODE_TEST_CHECKLIST"
      printf '%s\n' 'Error: status code 499'
      exit 1
    fi
    sed 's/\[ \]/[x]/g' "$OPENCODE_TEST_CHECKLIST" >"$OPENCODE_TEST_CHECKLIST.next"
    mv "$OPENCODE_TEST_CHECKLIST.next" "$OPENCODE_TEST_CHECKLIST"
    printf '%s\n' 'WIZARDRY_CHECKLIST_COMPLETE'
    ;;
  cancel-without-progress)
    printf '%s\n' 'Error: status code 499'
    exit 1
    ;;
  fail)
    exit 7
    ;;
esac
SH
  chmod +x "$moc_stub_dir/opencode"
}

write_remote_config() {
  config_home=$1
  mkdir -p "$config_home/opencode"
  cat >"$config_home/opencode/opencode.jsonc" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "github-copilot/gpt-5.3-codex"
}
EOF
}

test_help() {
  run_spell "spells/spellcraft/loop-code" --help
  assert_success || return 1
  assert_output_contains "Usage: loop-code" || return 1
  assert_output_contains "--local|--remote" || return 1
  assert_output_contains "--batch|--no-batch" || return 1
}

test_missing_checklist_fails() {
  tmp=$(make_tempdir)
  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    "$ROOT_DIR/spells/spellcraft/loop-code"
  assert_failure || return 1
  assert_error_contains "expected CHECKLIST.md or checklist.md" || return 1
}

test_default_checklist_uppercase_is_used() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  write_remote_config "$tmp/.config"
  checklist="$tmp/CHECKLIST.md"
  printf '%s\n' '- [ ] first task' '- [ ] second task' >"$checklist"

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code"

  assert_success || return 1
  [ "$(cat "$tmp/count")" = "2" ] || {
    TEST_FAILURE_REASON="expected two OpenCode rounds"
    return 1
  }
}

test_default_checklist_lowercase_fallback() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  write_remote_config "$tmp/.config"
  checklist="$tmp/checklist.md"
  printf '%s\n' '- [ ] first task' '- [ ] second task' >"$checklist"

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code"

  assert_success || return 1
  [ "$(cat "$tmp/count")" = "2" ] || {
    TEST_FAILURE_REASON="expected two OpenCode rounds"
    return 1
  }
}

test_complete_checklist_exits_without_opencode() {
  tmp=$(make_tempdir)
  checklist="$tmp/done checklist.md"
  printf '%s\n' '- [x] already done' >"$checklist"
  run_spell "spells/spellcraft/loop-code" "$checklist"
  assert_success || return 1
  assert_output_contains "already complete" || return 1
}

test_loops_until_complete_and_pins_session_and_model() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  write_remote_config "$tmp/.config"
  checklist="$tmp/checklist with spaces;safe.md"
  printf '%s\n' '- [ ] first task' '- [ ] second task' >"$checklist"
  log="$tmp/opencode.log"
  count="$tmp/count"

  run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_LOG="$log" \
    OPENCODE_TEST_COUNT="$count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    OPENCODE_TEST_REWRITE_CONFIG="$tmp/.config/opencode/opencode.jsonc" \
    "$ROOT_DIR/spells/spellcraft/loop-code" \
    "$checklist"

  assert_success || return 1
  assert_output_contains "OpenCode round 1" || return 1
  assert_output_contains "OpenCode round 2" || return 1
  assert_output_contains "Checklist complete" || return 1
  [ "$(cat "$count")" = "2" ] || {
    TEST_FAILURE_REASON="expected two OpenCode rounds"
    return 1
  }
  model_count=$(grep -F -- '--model github-copilot/gpt-5.3-codex' "$log" | wc -l | tr -d ' ')
  [ "$model_count" = "2" ] || {
    TEST_FAILURE_REASON="loop-code did not pin the first-round model across rounds"
    return 1
  }
  grep -F -- '--title loop-code-' "$log" >/dev/null || {
    TEST_FAILURE_REASON="initial round did not start a uniquely titled session"
    return 1
  }
  grep -F -- '--session ses_test_loop_code' "$log" >/dev/null || {
    TEST_FAILURE_REASON="subsequent rounds were not pinned to the original session"
    return 1
  }
  if grep -F -- '--continue' "$log" >/dev/null; then
    TEST_FAILURE_REASON="loop-code should not rely on OpenCode --continue"
    return 1
  fi
  if grep -F 'LOOP-CODE STATE BEGIN' "$checklist" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="loop-code should clear checklist state after completion"
    return 1
  fi
}

test_remote_defaults_to_batch() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  write_remote_config "$tmp/.config"
  checklist="$tmp/CHECKLIST.md"
  printf '%s\n' '- [ ] first task' '- [ ] second task' >"$checklist"

  run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist"

  assert_success || return 1
  grep -F 'largest coherent batch' "$tmp/log" >/dev/null || {
    TEST_FAILURE_REASON="remote default should use batch mode"
    return 1
  }
}

test_local_defaults_to_no_batch() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  write_remote_config "$tmp/.config"
  checklist="$tmp/CHECKLIST.md"
  printf '%s\n' '- [ ] first task' '- [ ] second task' >"$checklist"

  run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist" --model "ollama/qwen3-coder:30b"

  assert_success || return 1
  grep -F 'Complete the next unchecked checklist item' "$tmp/log" >/dev/null || {
    TEST_FAILURE_REASON="local models should default to no-batch mode"
    return 1
  }
}

test_batch_override_for_local() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  write_remote_config "$tmp/.config"
  checklist="$tmp/CHECKLIST.md"
  printf '%s\n' '- [ ] first task' '- [ ] second task' >"$checklist"

  run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist" --model "ollama/qwen3-coder:30b" --batch

  assert_success || return 1
  grep -F 'largest coherent batch' "$tmp/log" >/dev/null || {
    TEST_FAILURE_REASON="--batch should override the local no-batch default"
    return 1
  }
}

test_direction_phrase_stops_loop() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  write_remote_config "$tmp/.config"
  checklist="$tmp/TODO.md"
  printf '%s\n' '- [ ] blocked task' >"$checklist"

  run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_MODE=direction \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist"

  assert_failure || return 1
  assert_error_contains "requested direction" || return 1
}

test_false_completion_claim_continues() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  write_remote_config "$tmp/.config"
  checklist="$tmp/TODO.md"
  printf '%s\n' '- [ ] unfinished task' >"$checklist"

  run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_MODE=false-complete \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist"

  assert_success || return 1
  assert_error_contains "reported completion" || return 1
}

test_vague_direction_refusal_continues() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  write_remote_config "$tmp/.config"
  checklist="$tmp/TODO.md"
  printf '%s\n' '- [ ] large architectural task' >"$checklist"

  run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_MODE=balk \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist"

  assert_success || return 1
  assert_error_contains "ignored a direction request" || return 1
}

test_opencode_failure_is_reported() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  write_remote_config "$tmp/.config"
  checklist="$tmp/TODO.md"
  printf '%s\n' '- [ ] task' >"$checklist"

  run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_MODE=fail \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist"

  assert_failure || return 1
  assert_error_contains "OpenCode round 1 failed with status 7" || return 1
}

test_status_499_with_progress_continues() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  write_remote_config "$tmp/.config"
  checklist="$tmp/TODO.md"
  printf '%s\n' '- [ ] first task' '- [ ] second task' >"$checklist"

  run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_MODE=cancel-after-progress \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist"

  assert_success || return 1
  assert_error_contains "status code 499 after completing 1 checklist item(s); continuing" || return 1
}

test_status_499_without_progress_fails() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  write_remote_config "$tmp/.config"
  checklist="$tmp/TODO.md"
  printf '%s\n' '- [ ] task' >"$checklist"

  run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_MODE=cancel-without-progress \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist"

  assert_failure || return 1
  assert_error_contains "OpenCode round 1 failed with status 1" || return 1
}

run_test_case "loop-code shows help" test_help
run_test_case "loop-code requires checklist defaults" test_missing_checklist_fails
run_test_case "loop-code defaults to CHECKLIST.md" test_default_checklist_uppercase_is_used
run_test_case "loop-code falls back to checklist.md" test_default_checklist_lowercase_fallback
run_test_case "loop-code recognizes completion" test_complete_checklist_exits_without_opencode
run_test_case "loop-code pins session and model" test_loops_until_complete_and_pins_session_and_model
run_test_case "loop-code defaults remote runs to batch" test_remote_defaults_to_batch
run_test_case "loop-code defaults local runs to no-batch" test_local_defaults_to_no_batch
run_test_case "loop-code allows local batch override" test_batch_override_for_local
run_test_case "loop-code honors direction phrase" test_direction_phrase_stops_loop
run_test_case "loop-code rejects false completion" test_false_completion_claim_continues
run_test_case "loop-code ignores vague direction refusal" test_vague_direction_refusal_continues
run_test_case "loop-code reports OpenCode failure" test_opencode_failure_is_reported
run_test_case "loop-code continues after status 499 with progress" test_status_499_with_progress_continues
run_test_case "loop-code fails on status 499 without progress" test_status_499_without_progress_fails

finish_tests
