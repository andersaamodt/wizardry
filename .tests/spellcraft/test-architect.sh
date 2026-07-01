#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

make_architect_opencode_stub() {
  stub_dir=$1
  mkdir -p "$stub_dir"
  cat >"$stub_dir/opencode" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >>"$ARCHITECT_TEST_LOG"
checklist=$ARCHITECT_TEST_CHECKLIST
if [ "${ARCHITECT_TEST_MODE:-rewrite}" = "rewrite" ]; then
  {
    printf '%s\n' '# Checklist'
    printf '%s\n' ''
    printf '%s\n' '- [x] Keep completed work.'
    printf '%s\n' '- [ ] In `src/auth.js`, move token parsing into `readAuthCookie`; verify with `node --check src/auth.js`.'
    printf '%s\n' '- [ ] In `.tests/test-auth.sh`, add a cookie-spoof regression for `readAuthCookie`; verify with `.tests/test-auth.sh`.'
  } >"$checklist"
fi
printf '%s\n' 'architect test output'
SH
  chmod +x "$stub_dir/opencode"
}

write_architect_remote_config() {
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
  run_spell "spells/spellcraft/architect" --help
  assert_success || return 1
  assert_output_contains "Usage: architect" || return 1
  assert_output_contains "--local|--remote" || return 1
}

test_missing_checklist_fails() {
  tmp=$(make_tempdir)
  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    "$ROOT_DIR/spells/spellcraft/architect"
  assert_failure || return 1
  assert_error_contains "expected CHECKLIST.md or checklist.md" || return 1
}

test_rewrites_default_checklist_with_explicit_model() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_architect_opencode_stub "$stub_dir"
  checklist="$tmp/CHECKLIST.md"
  printf '%s\n' '# Checklist' '' '- [x] Keep completed work.' '- [ ] Fix auth architecture.' >"$checklist"

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    ARCHITECT_TEST_LOG="$tmp/log" \
    ARCHITECT_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/architect" --model "test/model"

  assert_success || return 1
  grep -F -- '--model test/model' "$tmp/log" >/dev/null || {
    TEST_FAILURE_REASON="architect should pass the explicit OpenCode model"
    return 1
  }
  grep -F 'Edit only this checklist file' "$tmp/log" >/dev/null || {
    TEST_FAILURE_REASON="architect prompt should constrain edits to the checklist"
    return 1
  }
  grep -F 'file-scoped' "$tmp/log" >/dev/null || {
    TEST_FAILURE_REASON="architect prompt should request file-scoped items"
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

test_remote_uses_configured_nonlocal_model() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  make_architect_opencode_stub "$stub_dir"
  write_architect_remote_config "$tmp/.config"
  checklist="$tmp/checklist.md"
  printf '%s\n' '- [ ] Fix broad thing.' >"$checklist"

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    HOME="$tmp" \
    XDG_CONFIG_HOME="$tmp/.config" \
    XDG_STATE_HOME="$tmp/.state" \
    PATH="$stub_dir:$PATH" \
    ARCHITECT_TEST_LOG="$tmp/log" \
    ARCHITECT_TEST_CHECKLIST="$checklist" \
    "$ROOT_DIR/spells/spellcraft/architect" --remote

  assert_success || return 1
  grep -F -- '--model github-copilot/gpt-5.3-codex' "$tmp/log" >/dev/null || {
    TEST_FAILURE_REASON="architect --remote should use the configured OpenCode model"
    return 1
  }
}

run_test_case "architect shows help" test_help
run_test_case "architect requires checklist defaults" test_missing_checklist_fails
run_test_case "architect rewrites default checklist with explicit model" \
  test_rewrites_default_checklist_with_explicit_model
run_test_case "architect remote uses configured nonlocal model" \
  test_remote_uses_configured_nonlocal_model

finish_tests
