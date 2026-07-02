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
  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    PATH="$tmp/bin:$PATH" \
    "$ROOT_DIR/spells/spellcraft/architect" "$@"
}

test_help() {
  run_spell "spells/spellcraft/architect" --help
  assert_success || return 1
  assert_output_contains "architect a simple pong game based on Godot" || return 1
  assert_output_contains "--checklist CHECKLIST.md" || return 1
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
  grep -F 'a simple pong game based on Godot' "$tmp/opencode-prompt-log" >/dev/null || {
    TEST_FAILURE_REASON="architect should join freeform args into one brief"
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

test_default_does_not_overwrite_existing_checklist() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [ ] Original broad work.' >"$tmp/CHECKLIST.md"
  write_valid_model_output "$tmp/model-output"

  run_architect_with_stub "$tmp" CHECKLIST.md

  assert_success || return 1
  grep -F -- '- [ ] Original broad work.' "$tmp/CHECKLIST.md" >/dev/null || {
    TEST_FAILURE_REASON="architect should not overwrite an existing checklist"
    return 1
  }
  assert_output_contains "src/auth.js" || return 1
}

test_checklist_context_preserves_completed_items_in_output() {
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

  run_architect_with_stub "$tmp" --checklist CHECKLIST.md improve auth architecture

  assert_success || return 1
  assert_output_contains "- [x] Keep completed work." || return 1
  assert_output_contains "src/auth.js" || return 1
  grep -F -- '- [ ] Fix auth architecture.' "$tmp/CHECKLIST.md" >/dev/null || {
    TEST_FAILURE_REASON="architect should not modify checklist context directly"
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

- [ ] Create paddle script scripts/paddle.gd; verify with `gdcheck scripts/paddle.gd 2>/dev/null || true`
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

  run_architect_with_stub "$tmp" --checklist CHECKLIST.md improve auth
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

  run_architect_with_stub "$tmp" --checklist CHECKLIST.md improve auth
  assert_failure || return 1
  assert_error_contains "broad unchecked item remained" || return 1
}

run_test_case "architect shows humane stdout help" test_help
run_test_case "architect requires brief or checklist" test_missing_brief_or_checklist_fails
run_test_case "architect rejects remote models" test_rejects_remote_model
run_test_case "architect joins freeform args into a brief" test_freeform_args_are_joined_into_brief
run_test_case "architect keeps stdout to final checklist only" test_stdout_contains_only_final_checklist
run_test_case "architect does not blindly overwrite checklists" test_default_does_not_overwrite_existing_checklist
run_test_case "architect preserves completed context in output" \
  test_checklist_context_preserves_completed_items_in_output
run_test_case "architect accepts explicit MLX local model" test_accepts_explicit_mlx_local_model
run_test_case "architect rejects malformed checkboxes" test_rejects_malformed_checkbox
run_test_case "architect rejects missing verification commands" test_rejects_missing_verification_command
run_test_case "architect rejects extra backticked paths" test_rejects_extra_backticked_path
run_test_case "architect rejects missing target paths" test_rejects_missing_target_path
run_test_case "architect accepts Godot res paths" test_accepts_godot_res_paths_and_slashy_prose
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
