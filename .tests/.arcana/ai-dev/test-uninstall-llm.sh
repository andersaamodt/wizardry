#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/uninstall-llm" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "uninstall-llm" || return 1
}

test_requires_model_name() {
  run_spell "spells/.arcana/ai-dev/uninstall-llm"
  assert_failure
}

test_requires_runtime() {
  AI_DEV_FORCE_NONE=1 AI_DEV_MLX_SUPPORTED=0 run_spell "spells/.arcana/ai-dev/uninstall-llm" "qwen3-coder:30b"
  assert_failure || return 1
  assert_error_contains "not installed" || return 1
}

test_reports_requested_model_after_sync() {
  tmp=$(make_tempdir)
  stub_dir="$tmp/stubs"
  mkdir -p "$stub_dir" "$tmp/state/wizardry/ai-dev/mlx/venv/bin"
  cat >"$stub_dir/is-ai-component-installed" <<'SH'
#!/bin/sh
[ "$1" = mlx ]
SH
  cat >"$tmp/state/wizardry/ai-dev/mlx/venv/bin/python" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$stub_dir/is-ai-component-installed" \
    "$tmp/state/wizardry/ai-dev/mlx/venv/bin/python"
  : >"$tmp/state/wizardry/ai-dev/mlx/installed"
  printf '%s\n' 'mlx' >"$tmp/state/wizardry/ai-dev/active-runtime"
  printf '%s\n' 'mlx-community/Qwen3-Coder-30B-A3B-Instruct-5bit' \
    >"$tmp/state/wizardry/ai-dev/selected-model-mlx"
  printf '%s\n' 'mlx-community/Qwen3-Coder-Next-5bit' \
    >"$tmp/state/wizardry/ai-dev/mlx-installed-models"

  RUN_CMD_WORKDIR="$tmp" run_cmd env \
    HOME="$tmp" \
    XDG_STATE_HOME="$tmp/state" \
    XDG_CONFIG_HOME="$tmp/config" \
    PATH="$stub_dir:$PATH" \
    AI_DEV_SKIP_MLX_SERVER_START=1 \
    "$ROOT_DIR/spells/.arcana/ai-dev/uninstall-llm" \
    mlx-community/Qwen3-Coder-Next-5bit

  assert_success || return 1
  assert_output_contains "LLM model uninstalled: mlx-community/Qwen3-Coder-Next-5bit" || return 1
}

run_test_case "uninstall-llm shows help" test_help
run_test_case "uninstall-llm requires model name" test_requires_model_name
run_test_case "uninstall-llm requires runtime installed" test_requires_runtime
run_test_case "uninstall-llm reports requested model after sync" \
  test_reports_requested_model_after_sync

finish_tests
