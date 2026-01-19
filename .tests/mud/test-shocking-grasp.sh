#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_shocking_grasp_charges_avatar() {
  # Create test directory
  test_tempdir=$(mktemp -d)
  
  # Create avatar
  avatar_path="$test_tempdir/.testuser"
  mkdir -p "$avatar_path"
  # Note: test uses temp config, no need to set avatar-path
  enchant "$avatar_path" "is_avatar=1" >/dev/null 2>&1 || true
  
  # Cast shocking-grasp
  run_spell "spells/mud/shocking-grasp"
  assert_success && assert_output_contains "electrical energy"
  
  # Verify on_toucher effect was added
  on_toucher=$(read-magic "$avatar_path" on_toucher 2>/dev/null || printf '')
  [ "$on_toucher" = "damage:4" ] || fail "Expected on_toucher=damage:4, got: $on_toucher"
}

test_shocking_grasp_requires_avatar() {
  # No avatar setup - spell should fail
  
  # Try without avatar
  run_spell "spells/mud/shocking-grasp"
  assert_failure && assert_stderr_contains "no avatar found"
}

run_test_case "shocking-grasp charges avatar with electrical damage" test_shocking_grasp_charges_avatar
run_test_case "shocking-grasp requires avatar to be enabled" test_shocking_grasp_requires_avatar
finish_tests
