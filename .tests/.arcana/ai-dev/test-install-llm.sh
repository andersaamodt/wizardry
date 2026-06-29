#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/install-llm" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "install-llm" || return 1
}

test_requires_model_name() {
  run_spell "spells/.arcana/ai-dev/install-llm"
  assert_failure
}

test_requires_runtime() {
  AI_DEV_FORCE_NONE=1 AI_DEV_MLX_SUPPORTED=0 run_spell "spells/.arcana/ai-dev/install-llm" "qwen3-coder:30b"
  assert_failure || return 1
  assert_error_contains "not installed" || return 1
}

test_mlx_download_uses_fast_visible_transfer() {
  install_llm_spell="$test_root/spells/.arcana/ai-dev/install-llm"

  if grep -F 'max_workers=1' "$install_llm_spell" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="MLX model downloads are still forced through one Hugging Face worker"
    return 1
  fi
  grep -F 'HF_HUB_DISABLE_XET=1' "$install_llm_spell" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX model downloads still use the slow Xet path"
    return 1
  }
  grep -F 'max_workers=4' "$install_llm_spell" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="MLX model downloads do not use the measured four-worker transfer"
    return 1
  }
  if sed -n '/snapshot_download/,/failed to install/p' "$install_llm_spell" |
     grep -E '>/dev/null|2>/dev/null|2>&1' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="MLX model download progress is hidden from the terminal"
    return 1
  fi
}

run_test_case "install-llm shows help" test_help
run_test_case "install-llm requires model name" test_requires_model_name
run_test_case "install-llm requires runtime installed" test_requires_runtime
run_test_case "install-llm keeps MLX downloads fast and visible" test_mlx_download_uses_fast_visible_transfer

finish_tests
