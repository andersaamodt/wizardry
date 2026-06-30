#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_mlx_server_uses_local_snapshot_resolution() {
  helper="$test_root/spells/.arcana/ai-dev/ai-dev-llm-common"
  grep -F 'snapshot_download(repo_id=os.environ["AI_DEV_MLX_MODEL"], local_files_only=True)' \
    "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX helper does not resolve local Hugging Face snapshots before server start"
    return 1
  }
}

test_mlx_server_normalizes_list_extra_special_tokens() {
  helper="$test_root/spells/.arcana/ai-dev/ai-dev-llm-common"
  grep -F 'extra_special_tokens = config.get("extra_special_tokens")' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX helper does not inspect tokenizer extra_special_tokens"
    return 1
  }
  grep -F 'config.pop("extra_special_tokens", None)' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX helper does not normalize list-valued extra_special_tokens"
    return 1
  }
}

test_mlx_server_prefers_entrypoint_and_longer_timeout() {
  helper="$test_root/spells/.arcana/ai-dev/ai-dev-llm-common"
  grep -F 'ai_llm_mlx_server_bin=$ai_llm_mlx_venv/bin/mlx_lm.server' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX helper does not prefer the mlx_lm.server entrypoint"
    return 1
  }
  grep -F 'ai_llm_mlx_start_timeout=${AI_DEV_MLX_START_TIMEOUT:-120}' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX helper does not expose the longer MLX startup timeout"
    return 1
  }
  grep -F 'if ai_llm_wait_for_mlx_server_timeout 2; then' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX helper does not use a short preflight probe before starting a fresh server"
    return 1
  }
}

test_opencode_model_resolution_prefers_explicit_mlx_model() {
  tmp=$(make_tempdir)
  output=$(
    env HOME="$tmp" XDG_CONFIG_HOME="$tmp/.config" sh -c '
      . "'"$test_root"'/spells/.arcana/ai-dev/ai-dev-llm-common"
      ai_llm_resolve_opencode_mlx_model "mlx/mlx-community/Qwen3-Coder-Next-5bit"
    '
  ) || {
    TEST_FAILURE_REASON="explicit MLX model was not accepted"
    return 1
  }
  [ "$output" = "mlx-community/Qwen3-Coder-Next-5bit" ] || {
    TEST_FAILURE_REASON="explicit MLX model did not resolve to the repository model id"
    return 1
  }
}

test_opencode_model_resolution_reads_jsonc_config() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/.config/opencode"
  cat >"$tmp/.config/opencode/opencode.jsonc" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "mlx/mlx-community/Qwen3-Coder-Next-5bit"
}
EOF
  output=$(
    env HOME="$tmp" XDG_CONFIG_HOME="$tmp/.config" sh -c '
      . "'"$test_root"'/spells/.arcana/ai-dev/ai-dev-llm-common"
      ai_llm_resolve_opencode_mlx_model
    '
  ) || {
    TEST_FAILURE_REASON="OpenCode JSONC config model was not detected"
    return 1
  }
  [ "$output" = "mlx-community/Qwen3-Coder-Next-5bit" ] || {
    TEST_FAILURE_REASON="OpenCode JSONC config model did not resolve correctly"
    return 1
  }
}

run_test_case "ai-dev-llm-common resolves MLX models locally" test_mlx_server_uses_local_snapshot_resolution
run_test_case "ai-dev-llm-common normalizes Qwen tokenizer metadata" test_mlx_server_normalizes_list_extra_special_tokens
run_test_case "ai-dev-llm-common prefers direct server entrypoint" test_mlx_server_prefers_entrypoint_and_longer_timeout
run_test_case "ai-dev-llm-common accepts explicit OpenCode MLX models" test_opencode_model_resolution_prefers_explicit_mlx_model
run_test_case "ai-dev-llm-common reads OpenCode JSONC model config" test_opencode_model_resolution_reads_jsonc_config

finish_tests
