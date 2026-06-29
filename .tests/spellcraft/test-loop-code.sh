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
printf '%s\n' "$*" >>"$OPENCODE_TEST_LOG"
count=0
[ ! -f "$OPENCODE_TEST_COUNT" ] || count=$(cat "$OPENCODE_TEST_COUNT")
count=$((count + 1))
printf '%s\n' "$count" >"$OPENCODE_TEST_COUNT"
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

test_help() {
  run_spell "spells/spellcraft/loop-code" --help
  assert_success || return 1
  assert_output_contains "Usage: loop-code" || return 1
  assert_output_contains "--model" || return 1
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
  checklist="$tmp/CHECKLIST.md"
  printf '%s\n' '- [ ] first task' '- [ ] second task' >"$checklist"

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
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
  checklist="$tmp/checklist.md"
  printf '%s\n' '- [ ] first task' '- [ ] second task' >"$checklist"

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
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

test_loops_until_complete_and_passes_model() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  checklist="$tmp/checklist with spaces;safe.md"
  printf '%s\n' '- [ ] first task' '- [ ] second task' >"$checklist"
  log="$tmp/opencode.log"
  count="$tmp/count"

  run_cmd env \
    HOME="$tmp" \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_LOG="$log" \
    OPENCODE_TEST_COUNT="$count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" \
    "$checklist" --model "ollama/qwen coder"

  assert_success || return 1
  assert_output_contains "OpenCode round 1" || return 1
  assert_output_contains "OpenCode round 2" || return 1
  assert_output_contains "Round 1 done" || return 1
  assert_output_contains "(~/${checklist##*/})" || return 1
  assert_output_contains "Checklist complete" || return 1
  [ "$(cat "$count")" = "2" ] || {
    TEST_FAILURE_REASON="expected two OpenCode rounds"
    return 1
  }
  grep -F -- '--model ollama/qwen coder' "$log" >/dev/null || {
    TEST_FAILURE_REASON="model option was not passed to OpenCode"
    return 1
  }
  grep -F -- '--continue' "$log" >/dev/null || {
    TEST_FAILURE_REASON="continue option was not passed to OpenCode"
    return 1
  }
  grep -F 'largest coherent batch' "$log" >/dev/null || {
    TEST_FAILURE_REASON="prompt did not request productive checklist batching"
    return 1
  }
  grep -F 'Continue after completing the first checkbox' "$log" >/dev/null || {
    TEST_FAILURE_REASON="prompt did not discourage stopping after one small item"
    return 1
  }
}

test_direction_phrase_stops_loop() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  checklist="$tmp/TODO.md"
  printf '%s\n' '- [ ] blocked task' >"$checklist"

  run_cmd env \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_MODE=direction \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist"

  assert_failure || return 1
  assert_error_contains "requested direction" || return 1
  [ "$(cat "$tmp/count")" = "1" ] || {
    TEST_FAILURE_REASON="direction request should stop after one round"
    return 1
  }
}

test_false_completion_claim_continues() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  checklist="$tmp/TODO.md"
  printf '%s\n' '- [ ] unfinished task' >"$checklist"

  run_cmd env \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_MODE=false-complete \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist"

  assert_success || return 1
  assert_error_contains "reported completion" || return 1
  [ "$(cat "$tmp/count")" = "2" ] || {
    TEST_FAILURE_REASON="false completion should not stop the loop"
    return 1
  }
}

test_vague_direction_refusal_continues() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  checklist="$tmp/TODO.md"
  printf '%s\n' '- [ ] large architectural task' >"$checklist"

  run_cmd env \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_MODE=balk \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist"

  assert_success || return 1
  assert_error_contains "ignored a direction request" || return 1
  [ "$(cat "$tmp/count")" = "2" ] || {
    TEST_FAILURE_REASON="vague refusal should not stop the loop"
    return 1
  }
}

test_opencode_failure_is_reported() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  checklist="$tmp/TODO.md"
  printf '%s\n' '- [ ] task' >"$checklist"

  run_cmd env \
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
  checklist="$tmp/TODO.md"
  printf '%s\n' '- [ ] first task' '- [ ] second task' >"$checklist"

  run_cmd env \
    PATH="$stub_dir:$PATH" \
    OPENCODE_TEST_MODE=cancel-after-progress \
    OPENCODE_TEST_LOG="$tmp/log" \
    OPENCODE_TEST_COUNT="$tmp/count" \
    OPENCODE_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/loop-code" "$checklist"

  assert_success || return 1
  assert_error_contains "status code 499 after completing 1 checklist item(s); continuing" || return 1
  [ "$(cat "$tmp/count")" = "2" ] || {
    TEST_FAILURE_REASON="status 499 after progress should continue to a second round"
    return 1
  }
}

test_status_499_without_progress_fails() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_opencode_stub "$stub_dir"
  checklist="$tmp/TODO.md"
  printf '%s\n' '- [ ] task' >"$checklist"

  run_cmd env \
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
run_test_case "loop-code loops and passes model" test_loops_until_complete_and_passes_model
run_test_case "loop-code honors direction phrase" test_direction_phrase_stops_loop
run_test_case "loop-code rejects false completion" test_false_completion_claim_continues
run_test_case "loop-code ignores vague direction refusal" test_vague_direction_refusal_continues
run_test_case "loop-code reports OpenCode failure" test_opencode_failure_is_reported
run_test_case "loop-code continues after status 499 with progress" test_status_499_with_progress_continues
run_test_case "loop-code fails on status 499 without progress" test_status_499_without_progress_fails

finish_tests
