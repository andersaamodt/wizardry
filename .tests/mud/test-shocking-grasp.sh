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
  enchant "$avatar_path" "is_avatar=1" >/dev/null 2>&1 || true
  enchant "$avatar_path" "mana=100" >/dev/null 2>&1 || true
  
  # Set up config file with avatar enabled
  mkdir -p "$test_tempdir/.mud"
  config_file="$test_tempdir/.mud/config"
  printf 'avatar=1\n' > "$config_file"
  printf 'avatar-path=%s\n' "$avatar_path" >> "$config_file"
  
  # Set SPELLBOOK_DIR for the spell to find the config
  SPELLBOOK_DIR="$test_tempdir"
  export SPELLBOOK_DIR
  
  # Cast shocking-grasp
  run_spell "spells/mud/shocking-grasp"
  assert_success && assert_output_contains "electrical energy"
  
  # Verify on_toucher effect was added
  on_toucher=$(read-magic "$avatar_path" on_toucher 2>/dev/null || printf '')
  [ "$on_toucher" = "damage:4" ] || fail "Expected on_toucher=damage:4, got: $on_toucher"
  
  # Cleanup
  rm -rf "$test_tempdir"
  unset SPELLBOOK_DIR
}

test_shocking_grasp_requires_avatar() {
  # No avatar setup - spell should fail
  
  # Try without avatar
  run_spell "spells/mud/shocking-grasp"
  assert_failure && assert_error_contains "no avatar found"
}

run_test_case "shocking-grasp charges avatar with electrical damage" test_shocking_grasp_charges_avatar
run_test_case "shocking-grasp requires avatar to be enabled" test_shocking_grasp_requires_avatar
finish_tests
