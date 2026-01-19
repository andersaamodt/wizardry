#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_shocking_grasp_charges_avatar() {
  _test_setup_mud_env
  
  # Create avatar
  avatar_path="$test_dir/.testuser"
  mkdir -p "$avatar_path"
  config-set "$test_config" "avatar-path" "$avatar_path"
  enchant "$avatar_path" "is_avatar=1" >/dev/null 2>&1 || true
  
  # Cast shocking-grasp
  _run_spell "spells/mud/shocking-grasp"
  _assert_success && _assert_output_contains "electrical energy"
  
  # Verify on_toucher effect was added
  on_toucher=$(read-magic "$avatar_path" on_toucher 2>/dev/null || printf '')
  [ "$on_toucher" = "damage:4" ] || _fail "Expected on_toucher=damage:4, got: $on_toucher"
}

test_shocking_grasp_requires_avatar() {
  _test_setup_mud_env
  
  # Try without avatar
  _run_spell "spells/mud/shocking-grasp"
  _assert_failure && _assert_stderr_contains "no avatar found"
}

_run_test_case "shocking-grasp charges avatar with electrical damage" test_shocking_grasp_charges_avatar
_run_test_case "shocking-grasp requires avatar to be enabled" test_shocking_grasp_requires_avatar
_finish_tests
