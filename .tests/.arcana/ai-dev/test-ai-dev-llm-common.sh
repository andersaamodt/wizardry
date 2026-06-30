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

test_mlx_server_patches_qwen_xml_tool_calls() {
  helper="$test_root/spells/.arcana/ai-dev/ai-dev-llm-common"
  grep -F 'WIZARDRY_QWEN_XML_TOOL_CALL_COMPAT' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX helper does not patch Qwen XML tool-call parsing"
    return 1
  }
  grep -F '<function=([^>\\n]+)>' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX tool parser patch does not recognize Qwen function tags"
    return 1
  }
  grep -F '<parameter=([^>\\n]+)>' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX tool parser patch does not recognize Qwen parameter tags"
    return 1
  }
  grep -F 'f"call_{uuid.uuid4().hex}"' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX tool parser patch does not generate string tool-call ids"
    return 1
  }
  grep -F 'decoded_arguments = json.loads(arguments)' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX tool parser patch does not normalize argument strings"
    return 1
  }
  grep -F 'numeric_xml_tool_fields = {"limit", "offset"}' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX tool parser patch does not coerce known numeric XML parameters"
    return 1
  }
  grep -F 'parameter_value = int(parameter_value)' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX tool parser patch does not emit numeric XML parameter values as numbers"
    return 1
  }
}

test_opencode_mlx_models_are_tool_call_capable() {
  helper="$test_root/spells/.arcana/ai-dev/ai-dev-llm-common"
  grep -F '"tool_call": true' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="OpenCode MLX model metadata does not enable tool calls"
    return 1
  }
  grep -F '"output": 4096' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="OpenCode MLX model metadata does not cap local output for speed"
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
  grep -F '<key>ProcessType</key>' "$helper" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX launchd helper does not mark the local server as interactive"
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

test_preferred_local_model_uses_selected_mlx_state_without_install_marker() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/.local/state/wizardry/ai-dev/mlx/venv/bin"
  printf '%s\n' '#!/bin/sh' 'exit 0' >"$tmp/.local/state/wizardry/ai-dev/mlx/venv/bin/mlx_lm.server"
  chmod +x "$tmp/.local/state/wizardry/ai-dev/mlx/venv/bin/mlx_lm.server"
  mkdir -p "$tmp/.local/state/wizardry/ai-dev"
  printf '%s\n' 'mlx-community/Qwen3-Coder-Next-5bit' >"$tmp/.local/state/wizardry/ai-dev/selected-model-mlx"

  output=$(
    env HOME="$tmp" XDG_STATE_HOME="$tmp/.local/state" sh -c '
      . "'"$test_root"'/spells/.arcana/ai-dev/ai-dev-llm-common"
      ai_llm_preferred_local_opencode_model
    '
  ) || {
    TEST_FAILURE_REASON="preferred local model should resolve from wizardry MLX state"
    return 1
  }
  [ "$output" = "mlx/mlx-community/Qwen3-Coder-Next-5bit" ] || {
    TEST_FAILURE_REASON="preferred local model did not use the selected MLX state"
    return 1
  }
}

test_ephemeral_mlx_server_survives_helper_return() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/bin" "$tmp/state"
  cat >"$tmp/bin/python" <<'SH'
#!/bin/sh
exit 0
SH
  cat >"$tmp/bin/mlx_lm.server" <<'SH'
#!/bin/sh
sleep 30
SH
  chmod +x "$tmp/bin/python" "$tmp/bin/mlx_lm.server"

  env TEST_TMP="$tmp" sh -c '
    . "'"$test_root"'/spells/.arcana/ai-dev/ai-dev-llm-common"
    ai_llm_mlx_python=$TEST_TMP/bin/python
    ai_llm_mlx_server_bin=$TEST_TMP/bin/mlx_lm.server
    ai_llm_root_dir=$TEST_TMP/state
    ai_llm_mlx_log=$TEST_TMP/state/server.log
    ai_llm_resolve_mlx_model_path() { printf "%s\n" "$1"; }
    ai_llm_prepare_mlx_model_compat() { return 0; }
    ai_llm_spawn_mlx_server_ephemeral test-model "$TEST_TMP/server.pid"
    server_pid=$(cat "$TEST_TMP/server.pid")
    kill -0 "$server_pid" 2>/dev/null || exit 1
    kill "$server_pid"
    wait "$server_pid" 2>/dev/null || :
  ' || {
    TEST_FAILURE_REASON="ephemeral MLX server did not survive helper return"
    return 1
  }
}

test_next_smaller_mlx_model_chain_is_defined() {
  tmp=$(make_tempdir)

  output=$(
    env HOME="$tmp" sh -c '
      . "'"$test_root"'/spells/.arcana/ai-dev/ai-dev-llm-common"
      printf "%s,%s,%s,%s\n" \
        "$(ai_llm_next_smaller_mlx_model mlx-community/Qwen3-Coder-30B-A3B-Instruct-5bit)" \
        "$(ai_llm_next_smaller_mlx_model mlx-community/Qwen3-Coder-Next-5bit)" \
        "$(ai_llm_next_smaller_mlx_model mlx-community/Qwen2.5-14B-Instruct-4bit 2>/dev/null || printf none)" \
        "$(ai_llm_next_smaller_mlx_model some/unknown-model 2>/dev/null || printf none)"
    '
  ) || {
    TEST_FAILURE_REASON="next-smaller MLX model helper did not execute"
    return 1
  }

  [ "$output" = "mlx-community/Qwen2.5-14B-Instruct-4bit,mlx-community/Qwen3-Coder-30B-A3B-Instruct-5bit,none,none" ] || {
    TEST_FAILURE_REASON="next-smaller MLX model helper did not return the expected fallback chain"
    return 1
  }
}

run_test_case "ai-dev-llm-common resolves MLX models locally" test_mlx_server_uses_local_snapshot_resolution
run_test_case "ai-dev-llm-common normalizes Qwen tokenizer metadata" test_mlx_server_normalizes_list_extra_special_tokens
run_test_case "ai-dev-llm-common patches Qwen XML tool calls" test_mlx_server_patches_qwen_xml_tool_calls
run_test_case "ai-dev-llm-common marks MLX tool-call models" test_opencode_mlx_models_are_tool_call_capable
run_test_case "ai-dev-llm-common prefers direct server entrypoint" test_mlx_server_prefers_entrypoint_and_longer_timeout
run_test_case "ai-dev-llm-common accepts explicit OpenCode MLX models" test_opencode_model_resolution_prefers_explicit_mlx_model
run_test_case "ai-dev-llm-common reads OpenCode JSONC model config" test_opencode_model_resolution_reads_jsonc_config
run_test_case "ai-dev-llm-common resolves preferred local MLX state" test_preferred_local_model_uses_selected_mlx_state_without_install_marker
run_test_case "ai-dev-llm-common keeps ephemeral MLX server alive" test_ephemeral_mlx_server_survives_helper_return
run_test_case "ai-dev-llm-common defines MLX fallback chain" test_next_smaller_mlx_model_chain_is_defined

finish_tests
