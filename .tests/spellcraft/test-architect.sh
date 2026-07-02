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
if [ "${1-}" = models ]; then
  printf '%s\n' 'ollama/qwen3.6:35b-a3b'
  printf '%s\n' 'mlx/mlx-community/Qwen3-Coder-30B-A3B-Instruct-5bit'
  exit 0
fi

[ "${1-}" = run ] || exit 64
shift
dir=
model=
title=
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
    printf '%s\n' "$1" >"$dir/opencode-prompt-log"
    ;;
  esac
  shift
done
printf '%s\n' "$dir" >"$dir/opencode-dir-log"
printf '%s\n' "$model" >"$dir/opencode-model-log"
printf '%s\n' "$title" >"$dir/opencode-title-log"
cp "$dir/model-output" "$dir/CHECKLIST.md"
SH
  chmod +x "$stub_dir/opencode"
}

write_fixture_files() {
  tmp=$1
  mkdir -p "$tmp/src" "$tmp/.tests"
  printf '%s\n' 'export function readAuthCookie() {}' >"$tmp/src/auth.js"
  printf '%s\n' '#!/bin/sh' 'node --check src/auth.js' >"$tmp/.tests/test-auth.sh"
  chmod +x "$tmp/.tests/test-auth.sh"
}

run_architect_with_stub() {
  tmp=$1
  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    PATH="$tmp/bin:$PATH" \
    "$ROOT_DIR/spells/spellcraft/architect" "$tmp/CHECKLIST.md"
}

test_help() {
  run_spell "spells/spellcraft/architect" --help
  assert_success || return 1
  assert_output_contains "Usage: architect" || return 1
  assert_output_contains "OpenCode" || return 1
  assert_output_contains "local-only" || return 1
}

test_missing_checklist_fails() {
  tmp=$(make_tempdir)
  RUN_CMD_WORKDIR="$tmp" run_cmd env "$ROOT_DIR/spells/spellcraft/architect"
  assert_failure || return 1
  assert_error_contains "expected CHECKLIST.md or checklist.md" || return 1
}

test_rejects_remote_model() {
  tmp=$(make_tempdir)
  printf '%s\n' '- [ ] Fix broad thing.' >"$tmp/CHECKLIST.md"
  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    "$ROOT_DIR/spells/spellcraft/architect" --model github-copilot/gpt-5.3-codex
  assert_failure || return 1
  assert_error_contains "must name a local OpenCode model" || return 1
}

test_rewrites_checklist_with_opencode() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [x] Keep completed work.' '- [ ] Fix auth architecture.' >"$tmp/CHECKLIST.md"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [x] Keep completed work.
- [ ] Verify src/auth.js rejects unsigned admin cookies: `node --input-type=module -e "import {readAuthCookie} from './src/auth.js'; if(readAuthCookie('admin=true').isAdmin) process.exit(1);"`
- [ ] Verify .tests/test-auth.sh runs without error: `sh .tests/test-auth.sh`
EOF

  run_architect_with_stub "$tmp"
  assert_success || return 1
  grep -F -- '- [x] Keep completed work.' "$tmp/CHECKLIST.md" >/dev/null || {
    TEST_FAILURE_REASON="architect should preserve completed checklist items"
    return 1
  }
  grep -F 'ollama/qwen3.6:35b-a3b' "$tmp/opencode-model-log" >/dev/null || {
    TEST_FAILURE_REASON="architect should pass the default local Ollama model"
    return 1
  }
  grep -F "$tmp" "$tmp/opencode-dir-log" >/dev/null || {
    TEST_FAILURE_REASON="architect should run OpenCode in the checklist directory"
    return 1
  }
  grep -F 'Edit only CHECKLIST.md' "$tmp/opencode-prompt-log" >/dev/null || {
    TEST_FAILURE_REASON="architect prompt should confine edits to the checklist"
    return 1
  }
}

test_accepts_explicit_mlx_local_model() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [ ] Fix auth architecture.' >"$tmp/CHECKLIST.md"
  cat >"$tmp/model-output" <<'EOF'
# Checklist

- [ ] Verify src/auth.js rejects unsigned admin cookies: `node --check src/auth.js`
EOF

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    PATH="$tmp/bin:$PATH" \
    "$ROOT_DIR/spells/spellcraft/architect" "$tmp/CHECKLIST.md" \
    --model mlx/mlx-community/Qwen3-Coder-30B-A3B-Instruct-5bit

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
  printf '%s\n' '# Checklist' '' '- [ ] Fix auth architecture.' >"$tmp/CHECKLIST.md"
  printf '%s\n' '# Checklist' '' '- [?] Broken src/auth.js: `node --check src/auth.js`' >"$tmp/model-output"

  run_architect_with_stub "$tmp"
  assert_failure || return 1
  assert_error_contains "malformed checkbox" || return 1
}

test_rejects_missing_verification_command() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [ ] Fix auth architecture.' >"$tmp/CHECKLIST.md"
  printf '%s\n' '# Checklist' '' '- [ ] Verify src/auth.js rejects unsigned admin cookies.' >"$tmp/model-output"

  run_architect_with_stub "$tmp"
  assert_failure || return 1
  assert_error_contains "exactly one backticked verification command" || return 1
}

test_rejects_extra_backticked_path() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [ ] Fix auth architecture.' >"$tmp/CHECKLIST.md"
  printf '%s\n' '# Checklist' '' '- [ ] Verify `src/auth.js` rejects unsigned admin cookies: `node --check src/auth.js`' >"$tmp/model-output"

  run_architect_with_stub "$tmp"
  assert_failure || return 1
  assert_error_contains "exactly one backticked verification command" || return 1
}

test_rejects_missing_file_path() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [ ] Fix auth architecture.' >"$tmp/CHECKLIST.md"
  printf '%s\n' '# Checklist' '' '- [ ] Verify src/missing.js rejects unsigned admin cookies: `node --check src/missing.js`' >"$tmp/model-output"

  run_architect_with_stub "$tmp"
  assert_failure || return 1
  assert_error_contains "exactly one existing file path" || return 1
}

test_rejects_lost_completed_item() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [x] Keep completed work.' '- [ ] Fix auth architecture.' >"$tmp/CHECKLIST.md"
  printf '%s\n' '# Checklist' '' '- [ ] Verify src/auth.js rejects unsigned admin cookies: `node --check src/auth.js`' >"$tmp/model-output"

  run_architect_with_stub "$tmp"
  assert_failure || return 1
  assert_error_contains "completed item was not preserved" || return 1
}

test_rejects_literal_newline_command() {
  tmp=$(make_tempdir)
  make_opencode_stub "$tmp"
  write_fixture_files "$tmp"
  printf '%s\n' '# Checklist' '' '- [ ] Fix auth architecture.' >"$tmp/CHECKLIST.md"
  printf '%s\n' '# Checklist' '' '- [ ] Verify src/auth.js rejects unsigned admin cookies: `node --check src/auth.js\\nsh .tests/test-auth.sh`' >"$tmp/model-output"

  run_architect_with_stub "$tmp"
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
- [ ] Verify src/auth.js rejects unsigned admin cookies: `node --check src/auth.js`
EOF

  run_architect_with_stub "$tmp"
  assert_failure || return 1
  assert_error_contains "broad unchecked item remained" || return 1
}

run_test_case "architect shows local-only OpenCode help" test_help
run_test_case "architect requires checklist defaults" test_missing_checklist_fails
run_test_case "architect rejects remote models" test_rejects_remote_model
run_test_case "architect rewrites checklist with OpenCode" test_rewrites_checklist_with_opencode
run_test_case "architect accepts explicit MLX local model" test_accepts_explicit_mlx_local_model
run_test_case "architect rejects malformed checkboxes" test_rejects_malformed_checkbox
run_test_case "architect rejects missing verification commands" test_rejects_missing_verification_command
run_test_case "architect rejects extra backticked paths" test_rejects_extra_backticked_path
run_test_case "architect rejects missing file paths" test_rejects_missing_file_path
run_test_case "architect rejects lost completed items" test_rejects_lost_completed_item
run_test_case "architect rejects literal newline commands" test_rejects_literal_newline_command
run_test_case "architect rejects retained broad items" test_rejects_retained_broad_item

finish_tests
