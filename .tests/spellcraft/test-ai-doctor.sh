#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/spellcraft/ai-doctor" --help
  assert_success || return 1
  assert_output_contains "Usage: ai-doctor" || return 1
  assert_output_contains "read-only" || return 1
}

test_reports_ready_stack() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/bin"
  fake_wizardry="$tmp/wizardry"
  mkdir -p "$stub_dir" "$fake_wizardry/spells/spellcraft" "$fake_wizardry/spells/.arcana/ai-dev"
  : >"$fake_wizardry/spells/spellcraft/program"
  : >"$fake_wizardry/spells/spellcraft/loop-code"
  : >"$fake_wizardry/spells/spellcraft/architect"
  chmod +x "$fake_wizardry/spells/spellcraft/program" \
    "$fake_wizardry/spells/spellcraft/loop-code" \
    "$fake_wizardry/spells/spellcraft/architect"
  cat >"$fake_wizardry/spells/.arcana/ai-dev/ai-dev-llm-common" <<'SH'
ai_llm_resolve_runtime() { printf '%s\n' ollama; }
ai_llm_runtime_label() { printf '%s\n' "$1"; }
ai_llm_opencode_model() { printf '%s\n' github-copilot/gpt-5.3-codex; }
ai_llm_preferred_local_coding_opencode_model() { printf '%s\n' ollama/qwen3.6:35b-a3b; }
SH
  cat >"$fake_wizardry/spells/.arcana/ai-dev/list-installed-llms" <<'SH'
#!/bin/sh
printf '%s\n' qwen3.6:35b-a3b
SH
  chmod +x "$fake_wizardry/spells/.arcana/ai-dev/list-installed-llms"
  cat >"$stub_dir/opencode" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$stub_dir/opencode"

  run_cmd env \
    HOME="$tmp/home" \
    WIZARDRY_DIR="$fake_wizardry" \
    PATH="$stub_dir:$fake_wizardry/spells/spellcraft:$fake_wizardry/spells/.arcana/ai-dev:$PATH" \
    "$ROOT_DIR/spells/spellcraft/ai-doctor"

  assert_success || return 1
  assert_output_contains "program: installed" || return 1
  assert_output_contains "loop-code: installed" || return 1
  assert_output_contains "architect: installed" || return 1
  assert_output_contains "opencode: installed" || return 1
  assert_output_contains "runtime: ollama" || return 1
  assert_output_contains "preferred local coding model: ollama/qwen3.6:35b-a3b" || return 1
  assert_output_contains "status: ready" || return 1
}

test_reports_missing_stack() {
  tmp=$(make_tempdir)
  fake_wizardry="$tmp/wizardry"
  mkdir -p "$fake_wizardry/spells/spellcraft" "$fake_wizardry/spells/.arcana/ai-dev"
  : >"$fake_wizardry/spells/spellcraft/program"
  : >"$fake_wizardry/spells/spellcraft/loop-code"
  : >"$fake_wizardry/spells/spellcraft/architect"
  chmod +x "$fake_wizardry/spells/spellcraft/program" \
    "$fake_wizardry/spells/spellcraft/loop-code" \
    "$fake_wizardry/spells/spellcraft/architect"
  cat >"$fake_wizardry/spells/.arcana/ai-dev/ai-dev-llm-common" <<'SH'
ai_llm_resolve_runtime() { printf '%s\n' ollama; }
ai_llm_runtime_label() { printf '%s\n' "$1"; }
ai_llm_opencode_model() { return 1; }
ai_llm_preferred_local_coding_opencode_model() { return 1; }
SH
  cat >"$fake_wizardry/spells/.arcana/ai-dev/list-installed-llms" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$fake_wizardry/spells/.arcana/ai-dev/list-installed-llms"

  run_cmd env \
    HOME="$tmp/home" \
    WIZARDRY_DIR="$fake_wizardry" \
    AI_DEV_OPENCODE_PATH="$tmp/missing-opencode" \
    PATH="$fake_wizardry/spells/spellcraft:$fake_wizardry/spells/.arcana/ai-dev:$PATH" \
    "$ROOT_DIR/spells/spellcraft/ai-doctor"

  assert_failure || return 1
  assert_output_contains "opencode: missing" || return 1
  assert_output_contains "status: needs attention" || return 1
}

run_test_case "ai-doctor shows help" test_help
run_test_case "ai-doctor reports ready stack" test_reports_ready_stack
run_test_case "ai-doctor reports missing stack" test_reports_missing_stack
