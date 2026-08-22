#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

runtime_actions_show_help() {
  for spell in install-mlx set-active-llm-runtime uninstall-mlx use-llm-model; do
    run_spell "spells/.arcana/ai-dev/$spell" --help
    assert_success || return 1
  done
}

install_mlx_rejects_unsupported_hosts() {
  run_cmd env AI_DEV_MLX_SUPPORTED=0 "$ROOT_DIR/spells/.arcana/ai-dev/install-mlx"
  assert_failure
}

set_active_runtime_requires_a_runtime() {
  run_spell spells/.arcana/ai-dev/set-active-llm-runtime
  assert_status 2
}

set_active_runtime_rejects_unknown_runtime() {
  run_spell spells/.arcana/ai-dev/set-active-llm-runtime unknown
  assert_status 2
}

use_llm_model_requires_a_model() {
  run_spell spells/.arcana/ai-dev/use-llm-model
  assert_status 2
}

uninstall_mlx_is_scoped_to_managed_state() {
  grep -q 'rm -rf "$ai_llm_mlx_root"' "$ROOT_DIR/spells/.arcana/ai-dev/uninstall-mlx"
}

run_test_case "AI runtime action spells show help" runtime_actions_show_help
run_test_case "install-mlx rejects unsupported hosts" install_mlx_rejects_unsupported_hosts
run_test_case "set-active-llm-runtime requires a runtime" set_active_runtime_requires_a_runtime
run_test_case "set-active-llm-runtime rejects an unknown runtime" set_active_runtime_rejects_unknown_runtime
run_test_case "use-llm-model requires a model" use_llm_model_requires_a_model
run_test_case "uninstall-mlx removes only managed MLX state" uninstall_mlx_is_scoped_to_managed_state
finish_tests
