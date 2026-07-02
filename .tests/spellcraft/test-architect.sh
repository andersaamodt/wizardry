#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

make_architect_mlx_stub() {
  state_home=$1
  stub_dir=$state_home/wizardry/ai-dev/mlx/venv/bin
  mkdir -p "$stub_dir"
  cat >"$stub_dir/mlx_lm.generate" <<'SH'
#!/bin/sh
prompt_file=$ARCHITECT_TEST_PROMPT
output_file=$ARCHITECT_TEST_OUTPUT
while [ "$#" -gt 0 ]; do
  case "$1" in
  --prompt)
    shift
    if [ "${1-}" = "-" ]; then
      cat >"$prompt_file"
    fi
    ;;
  --model)
    shift
    printf '%s\n' "$1" >"$ARCHITECT_TEST_MODEL_LOG"
    ;;
  esac
  [ "$#" -gt 0 ] || break
  shift
done
cat "$output_file"
SH
  chmod +x "$stub_dir/mlx_lm.generate"
  cat >"$stub_dir/python" <<'SH'
#!/bin/sh
if [ -n "${AI_DEV_MLX_MODEL-}" ]; then
  printf '%s\n' "/mock/hub/$AI_DEV_MLX_MODEL"
  exit 0
fi
exit 0
SH
  chmod +x "$stub_dir/python"
}

write_selected_mlx_model() {
  state_home=$1
  model=$2
  mkdir -p "$state_home/wizardry/ai-dev"
  printf '%s\n' "$model" >"$state_home/wizardry/ai-dev/selected-model-mlx"
}

test_help() {
  run_spell "spells/spellcraft/architect" --help
  assert_success || return 1
  assert_output_contains "Usage: architect" || return 1
  assert_output_contains "local-only" || return 1
  assert_output_contains "does not use remote models" || return 1
}

test_missing_checklist_fails() {
  tmp=$(make_tempdir)
  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    "$ROOT_DIR/spells/spellcraft/architect"
  assert_failure || return 1
  assert_error_contains "expected CHECKLIST.md or checklist.md" || return 1
}

test_rejects_remote_mode() {
  tmp=$(make_tempdir)
  printf '%s\n' '- [ ] Fix broad thing.' >"$tmp/CHECKLIST.md"
  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    XDG_STATE_HOME="$tmp/.state" \
    "$ROOT_DIR/spells/spellcraft/architect" --remote
  assert_failure || return 1
  assert_error_contains "local-only" || return 1
}

test_rejects_non_mlx_explicit_model() {
  tmp=$(make_tempdir)
  state_home=$tmp/.state
  make_architect_mlx_stub "$state_home"
  printf '%s\n' '- [ ] Fix broad thing.' >"$tmp/CHECKLIST.md"

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    XDG_STATE_HOME="$state_home" \
    "$ROOT_DIR/spells/spellcraft/architect" --model "github-copilot/gpt-5.3-codex"

  assert_failure || return 1
  assert_error_contains "only accepts mlx/MODEL" || return 1
}

test_rewrites_default_checklist_with_local_mlx() {
  tmp=$(make_tempdir)
  state_home=$tmp/.state
  make_architect_mlx_stub "$state_home"
  write_selected_mlx_model "$state_home" "mlx-community/Qwen3-30B-A3B-Thinking-2507-4bit"
  checklist="$tmp/CHECKLIST.md"
  prompt_log="$tmp/prompt"
  model_log="$tmp/model"
  output_file="$tmp/model-output"
  printf '%s\n' '# Checklist' '' '- [x] Keep completed work.' '- [ ] Fix auth architecture.' >"$checklist"
  cat >"$output_file" <<'EOF'
# Checklist

- [x] Keep completed work.
- [ ] In `src/auth.js`, move token parsing into `readAuthCookie`; verify with `node --check src/auth.js`.
- [ ] In `.tests/test-auth.sh`, add a cookie-spoof regression for `readAuthCookie`; verify with `.tests/test-auth.sh`.
EOF

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    XDG_STATE_HOME="$state_home" \
    ARCHITECT_TEST_PROMPT="$prompt_log" \
    ARCHITECT_TEST_MODEL_LOG="$model_log" \
    ARCHITECT_TEST_OUTPUT="$output_file" \
    "$ROOT_DIR/spells/spellcraft/architect"

  assert_success || return 1
  grep -F '/mock/hub/mlx-community/Qwen3-30B-A3B-Thinking-2507-4bit' "$model_log" >/dev/null || {
    TEST_FAILURE_REASON="architect should pass the resolved local MLX model path"
    return 1
  }
  grep -F 'Output the complete replacement contents' "$prompt_log" >/dev/null || {
    TEST_FAILURE_REASON="architect prompt should request a full replacement checklist"
    return 1
  }
  grep -F 'Preserve all completed [x] checklist items exactly' "$prompt_log" >/dev/null || {
    TEST_FAILURE_REASON="architect prompt should require completed item preservation"
    return 1
  }
  grep -F -- '- [x] Keep completed work.' "$checklist" >/dev/null || {
    TEST_FAILURE_REASON="architect should preserve completed checklist items"
    return 1
  }
  grep -F 'src/auth.js' "$checklist" >/dev/null || {
    TEST_FAILURE_REASON="architect should produce a file-scoped checklist item"
    return 1
  }
}

test_restores_missing_completed_items() {
  tmp=$(make_tempdir)
  state_home=$tmp/.state
  make_architect_mlx_stub "$state_home"
  write_selected_mlx_model "$state_home" "mlx-community/Qwen3-30B-A3B-Thinking-2507-4bit"
  checklist="$tmp/CHECKLIST.md"
  printf '%s\n' '# Checklist' '' '- [x] Keep completed work.' '- [ ] Fix auth architecture.' >"$checklist"
  printf '%s\n' '# Checklist' '' '- [ ] In `src/auth.js`, fix auth.' >"$tmp/model-output"

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    XDG_STATE_HOME="$state_home" \
    ARCHITECT_TEST_PROMPT="$tmp/prompt" \
    ARCHITECT_TEST_MODEL_LOG="$tmp/model" \
    ARCHITECT_TEST_OUTPUT="$tmp/model-output" \
    "$ROOT_DIR/spells/spellcraft/architect"

  assert_success || return 1
  grep -F -- '- [x] Keep completed work.' "$checklist" >/dev/null || {
    TEST_FAILURE_REASON="architect should restore missing completed checklist items"
    return 1
  }
  grep -F 'src/auth.js' "$checklist" >/dev/null || {
    TEST_FAILURE_REASON="architect should keep the generated unchecked checklist items"
    return 1
  }
}

test_extracts_final_checklist_after_thinking() {
  tmp=$(make_tempdir)
  state_home=$tmp/.state
  make_architect_mlx_stub "$state_home"
  write_selected_mlx_model "$state_home" "mlx-community/Qwen3-30B-A3B-Thinking-2507-4bit"
  checklist="$tmp/CHECKLIST.md"
  printf '%s\n' '# Checklist' '' '- [x] Keep completed work.' '- [ ] Fix auth architecture.' >"$checklist"
  cat >"$tmp/model-output" <<'EOF'
<think>
I should inspect the broad checklist item and split it carefully.
</think>

# Checklist

- [x] Keep completed work.
- [ ] In `src/auth.js`, move token parsing into `readAuthCookie`; verify with `node --check src/auth.js`.
EOF

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    XDG_STATE_HOME="$state_home" \
    ARCHITECT_TEST_PROMPT="$tmp/prompt" \
    ARCHITECT_TEST_MODEL_LOG="$tmp/model" \
    ARCHITECT_TEST_OUTPUT="$tmp/model-output" \
    "$ROOT_DIR/spells/spellcraft/architect"

  assert_success || return 1
  grep -F '<think>' "$checklist" >/dev/null && {
    TEST_FAILURE_REASON="architect should discard thinking text before writing checklist"
    return 1
  }
  grep -F 'src/auth.js' "$checklist" >/dev/null || {
    TEST_FAILURE_REASON="architect should write the final checklist after thinking text"
    return 1
  }
}

test_normalizes_new_checked_items_to_unchecked() {
  tmp=$(make_tempdir)
  state_home=$tmp/.state
  make_architect_mlx_stub "$state_home"
  write_selected_mlx_model "$state_home" "mlx-community/Qwen3-30B-A3B-Thinking-2507-4bit"
  checklist="$tmp/CHECKLIST.md"
  printf '%s\n' '# Checklist' '' '- [x] Keep completed work.' '- [ ] Fix auth architecture.' >"$checklist"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [x] Keep completed work.
- [x] In `src/auth.js`, move token parsing into `readAuthCookie`; verify with `node --check src/auth.js`.
EOF

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    XDG_STATE_HOME="$state_home" \
    ARCHITECT_TEST_PROMPT="$tmp/prompt" \
    ARCHITECT_TEST_MODEL_LOG="$tmp/model" \
    ARCHITECT_TEST_OUTPUT="$tmp/model-output" \
    "$ROOT_DIR/spells/spellcraft/architect"

  assert_success || return 1
  grep -F -- '- [ ] In `src/auth.js`, move token parsing' "$checklist" >/dev/null || {
    TEST_FAILURE_REASON="architect should normalize newly checked model items back to unchecked"
    return 1
  }
}

test_removes_retained_broad_items_after_split() {
  tmp=$(make_tempdir)
  state_home=$tmp/.state
  make_architect_mlx_stub "$state_home"
  write_selected_mlx_model "$state_home" "mlx-community/Qwen3-30B-A3B-Thinking-2507-4bit"
  checklist="$tmp/CHECKLIST.md"
  broad='- [ ] Fix auth architecture.'
  printf '%s\n' '# Checklist' '' '- [x] Keep completed work.' "$broad" >"$checklist"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [x] Keep completed work.
- [ ] Fix auth architecture.
- [ ] In `src/auth.js`, move token parsing into `readAuthCookie`; verify with `node --check src/auth.js`.
EOF

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    XDG_STATE_HOME="$state_home" \
    ARCHITECT_TEST_PROMPT="$tmp/prompt" \
    ARCHITECT_TEST_MODEL_LOG="$tmp/model" \
    ARCHITECT_TEST_OUTPUT="$tmp/model-output" \
    "$ROOT_DIR/spells/spellcraft/architect"

  assert_success || return 1
  grep -F -- "$broad" "$checklist" >/dev/null && {
    TEST_FAILURE_REASON="architect should remove retained broad original items after splitting them"
    return 1
  }
  grep -F 'src/auth.js' "$checklist" >/dev/null || {
    TEST_FAILURE_REASON="architect should keep the new narrow split item"
    return 1
  }
}

run_test_case "architect shows local-only help" test_help
run_test_case "architect requires checklist defaults" test_missing_checklist_fails
run_test_case "architect rejects removed remote mode" test_rejects_remote_mode
run_test_case "architect rejects non-MLX explicit model" test_rejects_non_mlx_explicit_model
run_test_case "architect rewrites default checklist with local MLX" \
  test_rewrites_default_checklist_with_local_mlx
run_test_case "architect restores missing completed items" test_restores_missing_completed_items
run_test_case "architect extracts final checklist after thinking" \
  test_extracts_final_checklist_after_thinking
run_test_case "architect normalizes new checked items" \
  test_normalizes_new_checked_items_to_unchecked
run_test_case "architect removes retained broad items after split" \
  test_removes_retained_broad_items_after_split

finish_tests
