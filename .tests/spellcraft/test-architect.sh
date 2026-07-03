#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

make_opencode_stub() {
  tmp=$1
  stub_dir=$tmp/bin
  mkdir -p "$stub_dir"
  cat >"$stub_dir/opencode" <<'SH'
#!/bin/sh
[ "${1-}" = run ] || exit 64
shift
dir=
model=
title=
log_dir=$(pwd -P)
while [ "$#" -gt 0 ]; do
  case "$1" in
  --dir)
    shift
    dir=$1
    ;;
  --model)
    shift
    model=$1
    ;;
  --title)
    shift
    title=$1
    ;;
  *)
    printf '%s\n' "$1" >"$log_dir/opencode-prompt-log"
    ;;
  esac
  shift
done
printf '%s\n' "$dir" >"$log_dir/opencode-dir-log"
printf '%s\n' "$model" >"$log_dir/opencode-model-log"
printf '%s\n' "$title" >"$log_dir/opencode-title-log"
printf '%s\n' 'OpenCode progress line from stub'
cp "$log_dir/model-output" "$dir/CHECKLIST.md"
if [ -n "${ARCHITECT_TEST_CREATE_TARGET:-}" ]; then
  printf '%s\n' '# Concurrent checklist' >"$log_dir/CHECKLIST.md"
fi
SH
  chmod +x "$stub_dir/opencode"
  cat >"$stub_dir/ollama" <<'SH'
#!/bin/sh
[ "${1-}" = list ] || exit 64
printf '%s\n' 'NAME ID SIZE MODIFIED'
printf '%s\n' 'qwen3.6:35b-a3b abc 23GB now'
SH
  chmod +x "$stub_dir/ollama"
}

write_local_selection() {
  state_home=$1
  mkdir -p "$state_home/wizardry/ai-dev"
  printf '%s\n' 'ollama' >"$state_home/wizardry/ai-dev/active-runtime"
  printf '%s\n' 'qwen3.6:35b-a3b' >"$state_home/wizardry/ai-dev/selected-model-ollama"
}

write_fixture_files() {
  tmp=$1
  mkdir -p "$tmp/src" "$tmp/.tests"
  printf '%s\n' 'export function readAuthCookie() {}' >"$tmp/src/auth.js"
  printf '%s\n' '#!/bin/sh' 'node --check src/auth.js' >"$tmp/.tests/test-auth.sh"
  chmod +x "$tmp/.tests/test-auth.sh"
}

write_valid_model_output() {
  path=$1
  cat >"$path" <<'EOF'
# Architecture checklist

- [ ] Add auth cookie parsing to src/auth.js; verify with `node --check src/auth.js`
- [ ] Add auth regression tests to .tests/test-auth.sh; verify with `sh .tests/test-auth.sh`
EOF
}

run_architect_with_stub() {
  tmp=$1
  shift
  write_local_selection "$tmp/.state"
  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    HOME="$tmp" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$tmp/bin:$PATH" \
    "$ROOT_DIR/spells/spellcraft/architect" "$@"
}

test_help() {
  run_spell "spells/spellcraft/architect" --help
  assert_success || return 1
  assert_output_contains "architect a simple pong game based on Godot" || return 1
  assert_output_contains "--checklist FILE" || return 1
  assert_output_contains "preferred local AI-dev" || return 1
  assert_output_contains "stdout" || return 1
}

test_missing_brief_or_checklist_fails() {
  tmp=$(make_tempdir)
  RUN_CMD_WORKDIR="$tmp" run_cmd env "$ROOT_DIR/spells/spellcraft/architect"
  assert_failure || return 1
  assert_error_contains "provide a brief" || return 1
}

test_rejects_remote_model() {
  tmp=$(make_tempdir)
  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    "$ROOT_DIR/spells/spellcraft/architect" --model github-copilot/gpt-5.3-codex \
    a simple pong game
  assert_failure || return 1
  assert_error_contains "must name a local OpenCode model" || return 1
}

test_freeform_args_are_joined_into_brief() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  write_valid_model_output "$tmp/model-output"

  run_architect_with_stub "$tmp" a simple pong game based on Godot

  assert_success || return 1
  assert_output_contains "# Architecture checklist" || return 1
  assert_output_contains "src/auth.js" || return 1
  assert_error_contains "OpenCode progress line from stub" || return 1
  grep -F 'src/auth.js' "$tmp/CHECKLIST.md" >/dev/null || {
    TEST_FAILURE_REASON="architect should write CHECKLIST.md by default"
    return 1
  }
  grep -F 'a simple pong game based on Godot' "$tmp/opencode-prompt-log" >/dev/null || {
    TEST_FAILURE_REASON="architect should join freeform args into one brief"
    return 1
  }
  grep -F "Hidden paths such as .tests, .github, and dotfiles" \
    "$tmp/opencode-prompt-log" >/dev/null || {
    TEST_FAILURE_REASON="architect should guide local models to read explicit hidden paths"
    return 1
  }
  grep -F "AGENTS.md or .AGENTS.md" "$tmp/opencode-prompt-log" >/dev/null || {
    TEST_FAILURE_REASON="architect should mention both AGENTS filename variants"
    return 1
  }
  grep -F "applicable .github/ standards" "$tmp/opencode-prompt-log" >/dev/null || {
    TEST_FAILURE_REASON="architect should tell local models to read applicable .github standards"
    return 1
  }
  grep -F "bad premise" "$tmp/opencode-prompt-log" >/dev/null || {
    TEST_FAILURE_REASON="architect should tell local models to preserve contracts over bad premises"
    return 1
  }
}

test_stdout_contains_only_final_checklist() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  write_valid_model_output "$tmp/model-output"

  run_architect_with_stub "$tmp" a simple pong game

  assert_success || return 1
  case "$OUTPUT" in
  *"architect:"*|*"OpenCode progress line from stub"*)
    TEST_FAILURE_REASON="architect stdout should contain only the final checklist"
    return 1
    ;;
  esac
  assert_error_contains "architect: asking local OpenCode model" || return 1
  assert_error_contains "OpenCode progress line from stub" || return 1
}

test_existing_checklist_fails_noninteractively_without_force() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [ ] Original broad work.' >"$tmp/CHECKLIST.md"
  write_valid_model_output "$tmp/model-output"

  run_architect_with_stub "$tmp" CHECKLIST.md

  assert_failure || return 1
  assert_error_contains "exists; use --force" || return 1
  grep -F -- '- [ ] Original broad work.' "$tmp/CHECKLIST.md" >/dev/null || {
    TEST_FAILURE_REASON="architect should not overwrite an existing checklist"
    return 1
  }
}

test_print_uses_existing_checklist_without_writing() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [x] Keep completed work.' '- [ ] Fix auth architecture.' >"$tmp/CHECKLIST.md"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [x] Keep completed work.
- [ ] Add auth cookie parsing to src/auth.js; verify with `node --check src/auth.js`
- [ ] Add auth regression tests to .tests/test-auth.sh; verify with `sh .tests/test-auth.sh`
EOF

  run_architect_with_stub "$tmp" --print --checklist CHECKLIST.md improve auth architecture

  assert_success || return 1
  assert_output_contains "- [x] Keep completed work." || return 1
  assert_output_contains "src/auth.js" || return 1
  grep -F -- '- [ ] Fix auth architecture.' "$tmp/CHECKLIST.md" >/dev/null || {
    TEST_FAILURE_REASON="architect should not modify checklist context directly"
    return 1
  }
}

test_force_replaces_existing_checklist_after_validation() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [ ] Original broad work.' >"$tmp/CHECKLIST.md"
  write_valid_model_output "$tmp/model-output"

  run_architect_with_stub "$tmp" --force improve auth architecture

  assert_success || return 1
  grep -F 'src/auth.js' "$tmp/CHECKLIST.md" >/dev/null || {
    TEST_FAILURE_REASON="architect --force should replace an existing checklist"
    return 1
  }
  assert_error_contains "architect: wrote" || return 1
}

test_concurrent_target_creation_fails_without_force() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  write_valid_model_output "$tmp/model-output"

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    HOME="$tmp" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$tmp/bin:$PATH" \
    ARCHITECT_TEST_CREATE_TARGET=1 \
    "$ROOT_DIR/spells/spellcraft/architect" improve auth architecture

  assert_failure || return 1
  assert_error_contains "exists; use --force" || return 1
  grep -F '# Concurrent checklist' "$tmp/CHECKLIST.md" >/dev/null || {
    TEST_FAILURE_REASON="architect should not overwrite a checklist created during planning"
    return 1
  }
}

test_accepts_explicit_mlx_local_model() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  write_valid_model_output "$tmp/model-output"

  run_architect_with_stub "$tmp" --model mlx/mlx-community/Qwen3-Coder-30B-A3B-Instruct-5bit \
    improve auth architecture

  assert_success || return 1
  grep -F 'mlx/mlx-community/Qwen3-Coder-30B-A3B-Instruct-5bit' "$tmp/opencode-model-log" >/dev/null || {
    TEST_FAILURE_REASON="architect should allow explicitly selected local MLX OpenCode models"
    return 1
  }
}

test_default_model_uses_ai_dev_selection() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  write_valid_model_output "$tmp/model-output"

  run_architect_with_stub "$tmp" improve auth architecture

  assert_success || return 1
  grep -F 'ollama/qwen3.6:35b-a3b' "$tmp/opencode-model-log" >/dev/null || {
    TEST_FAILURE_REASON="architect should derive its default model from ai-dev local selection"
    return 1
  }
}

test_rejects_malformed_checkbox() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [?] Broken src/auth.js; verify with `node --check src/auth.js`
EOF

  run_architect_with_stub "$tmp" improve auth
  assert_failure || return 1
  assert_error_contains "malformed checkbox" || return 1
}

test_rejects_missing_verification_command() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Add auth cookie parsing to src/auth.js.
EOF

  run_architect_with_stub "$tmp" improve auth
  assert_failure || return 1
  assert_error_contains "exactly one backticked verification command" || return 1
}

test_rejects_extra_backticked_path() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Add auth cookie parsing to `src/auth.js`; verify with `node --check src/auth.js`
EOF

  run_architect_with_stub "$tmp" improve auth
  assert_failure || return 1
  assert_error_contains "exactly one backticked verification command" || return 1
}

test_rejects_missing_target_path() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Add cookie parsing to the auth module; verify with `node --check src/auth.js`
EOF

  run_architect_with_stub "$tmp" improve auth
  assert_failure || return 1
  assert_error_contains "must name a target file path" || return 1
}

test_accepts_godot_res_paths_and_slashy_prose() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Create paddle script res://scripts/paddle.gd with move_up/move_down handling; verify with `grep -c "class_name Paddle" scripts/paddle.gd`
EOF

  run_architect_with_stub "$tmp" a simple pong game based on Godot
  assert_success || return 1
  assert_output_contains "res://scripts/paddle.gd" || return 1
}

test_accepts_extensionless_slash_target_paths() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  mkdir -p "$tmp/spells/cantrips"
  printf '%s\n' '#!/bin/sh' 'printf "%s\n" ok' >"$tmp/spells/cantrips/max-length"
  chmod +x "$tmp/spells/cantrips/max-length"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Update spells/cantrips/max-length help text without changing behavior; verify with `sh spells/cantrips/max-length --help`
EOF

  run_architect_with_stub "$tmp" improve spells/cantrips/max-length
  assert_success || return 1
  assert_output_contains "spells/cantrips/max-length" || return 1
}

test_accepts_hidden_extensionless_slash_target_paths() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  mkdir -p "$tmp/.tests/cantrips"
  printf '%s\n' '#!/bin/sh' 'exit 0' >"$tmp/.tests/cantrips/test-max-length"
  chmod +x "$tmp/.tests/cantrips/test-max-length"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Update .tests/cantrips/test-max-length coverage for help output; verify with `sh .tests/cantrips/test-max-length`
EOF

  run_architect_with_stub "$tmp" improve .tests/cantrips/test-max-length
  assert_success || return 1
  assert_output_contains ".tests/cantrips/test-max-length" || return 1
}

test_rejects_res_paths_inside_verification_commands() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Create paddle script res://scripts/paddle.gd; verify with `test -f res://scripts/paddle.gd`
EOF

  run_architect_with_stub "$tmp" a simple pong game based on Godot
  assert_failure || return 1
  assert_error_contains "filesystem paths" || return 1
}

test_rejects_masked_verification_commands() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Create paddle script scripts/paddle.gd; verify with `grep -q Paddle scripts/paddle.gd || echo "No paddle script found"`
EOF

  run_architect_with_stub "$tmp" a simple pong game based on Godot
  assert_failure || return 1
  assert_error_contains "must not mask failure" || return 1
}

test_rejects_invented_verification_tools() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Create paddle script scripts/paddle.gd; verify with `gdscript --check scripts/paddle.gd`
EOF

  run_architect_with_stub "$tmp" a simple pong game based on Godot
  assert_failure || return 1
  assert_error_contains "must not invent unavailable validators" || return 1
}

test_rejects_lost_completed_item() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [x] Keep completed work.' '- [ ] Fix auth architecture.' >"$tmp/CHECKLIST.md"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Add auth cookie parsing to src/auth.js; verify with `node --check src/auth.js`
EOF

  run_architect_with_stub "$tmp" --print --checklist CHECKLIST.md improve auth
  assert_failure || return 1
  assert_error_contains "completed item was not preserved" || return 1
}

test_rejects_literal_newline_command() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Add auth cookie parsing to src/auth.js; verify with `node --check src/auth.js\nsh .tests/test-auth.sh`
EOF

  run_architect_with_stub "$tmp" improve auth
  assert_failure || return 1
  assert_error_contains "literal" || return 1
}

test_rejects_retained_broad_item() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [ ] Fix auth architecture.' >"$tmp/CHECKLIST.md"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Fix auth architecture.
- [ ] Add auth cookie parsing to src/auth.js; verify with `node --check src/auth.js`
EOF

  run_architect_with_stub "$tmp" --print --checklist CHECKLIST.md improve auth
  assert_failure || return 1
  assert_error_contains "broad unchecked item remained" || return 1
}

run_test_case "architect shows humane stdout help" test_help
run_test_case "architect requires brief or checklist" test_missing_brief_or_checklist_fails
run_test_case "architect rejects remote models" test_rejects_remote_model
run_test_case "architect joins freeform args into a brief" test_freeform_args_are_joined_into_brief
run_test_case "architect keeps stdout to final checklist only" test_stdout_contains_only_final_checklist
run_test_case "architect refuses existing checklists without force" \
  test_existing_checklist_fails_noninteractively_without_force
run_test_case "architect --print preserves context without writing" \
  test_print_uses_existing_checklist_without_writing
run_test_case "architect --force replaces existing checklist" \
  test_force_replaces_existing_checklist_after_validation
run_test_case "architect detects checklist creation before write" \
  test_concurrent_target_creation_fails_without_force
run_test_case "architect accepts explicit MLX local model" test_accepts_explicit_mlx_local_model
run_test_case "architect default model follows ai-dev selection" \
  test_default_model_uses_ai_dev_selection
run_test_case "architect rejects malformed checkboxes" test_rejects_malformed_checkbox
run_test_case "architect rejects missing verification commands" test_rejects_missing_verification_command
run_test_case "architect rejects extra backticked paths" test_rejects_extra_backticked_path
run_test_case "architect rejects missing target paths" test_rejects_missing_target_path
run_test_case "architect accepts Godot res paths" test_accepts_godot_res_paths_and_slashy_prose
run_test_case "architect accepts extensionless slash target paths" \
  test_accepts_extensionless_slash_target_paths
run_test_case "architect accepts hidden extensionless slash target paths" \
  test_accepts_hidden_extensionless_slash_target_paths
run_test_case "architect rejects res paths in commands" \
  test_rejects_res_paths_inside_verification_commands
run_test_case "architect rejects masked verification commands" \
  test_rejects_masked_verification_commands
run_test_case "architect rejects invented verification tools" \
  test_rejects_invented_verification_tools
run_test_case "architect rejects lost completed items" test_rejects_lost_completed_item
run_test_case "architect rejects literal newline commands" test_rejects_literal_newline_command
run_test_case "architect rejects retained broad items" test_rejects_retained_broad_item

finish_tests
