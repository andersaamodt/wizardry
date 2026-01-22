#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_cd_hook_exists() {
  cd_hook_path="$test_root/spells/.imps/hook/cd-hook"
  [ -f "$cd_hook_path" ] && [ -x "$cd_hook_path" ]
}

test_cd_hook_runs_without_config() {
  # Should not fail even if config doesn't exist
  cd_hook_imp="$test_root/spells/.imps/hook/cd-hook"
  output=$("$cd_hook_imp" 2>&1)
  [ $? -eq 0 ]
}

test_cd_hook_with_config() {
  # Create a test config
  test_dir=$(mktemp -d)
  test_config="$test_dir/.mud/config"
  mkdir -p "$test_dir/.mud"
  printf 'cd-look=0\navatar=0\n' > "$test_config"
  
  SPELLBOOK_DIR="$test_dir"
  export SPELLBOOK_DIR
  
  cd_hook_imp="$test_root/spells/.imps/hook/cd-hook"
  output=$("$cd_hook_imp" 2>&1)
  result=$?
  
  rm -rf "$test_dir"
  [ $result -eq 0 ]
}

test_invoke_wizardry_checks_correct_config_key() {
  skip-if-compiled || return $?
  
  # This test verifies that invoke-wizardry checks for the same config key
  # that toggle-cd sets (cd-look=1)
  
  # Read invoke-wizardry to see what config key it checks
  invoke_wizardry_file="$ROOT_DIR/spells/.imps/sys/invoke-wizardry"
  
  # Check that it looks for cd-look=1 (not cd-hook=1)
  if ! grep -q 'grep -q "\^cd-look=1\$"' "$invoke_wizardry_file"; then
    TEST_FAILURE_REASON="invoke-wizardry should check for cd-look=1 (not cd-hook=1) to match toggle-cd"
    return 1
  fi
  
  # Make sure it's NOT checking for cd-hook=1
  if grep -q 'grep -q "\^cd-hook=1\$"' "$invoke_wizardry_file"; then
    TEST_FAILURE_REASON="invoke-wizardry is checking for cd-hook=1, but toggle-cd sets cd-look=1"
    return 1
  fi
  
  return 0
}

test_toggle_cd_sets_cd_look() {
  skip-if-compiled || return $?
  
  # Create temporary spellbook directory
  tmpdir=$(make_tempdir)
  test_spellbook="$tmpdir/.spellbook"
  mkdir -p "$test_spellbook"
  
  # Enable cd-look using toggle-cd
  output=$(env SPELLBOOK_DIR="$test_spellbook" sh "$ROOT_DIR/spells/.arcana/mud/toggle-cd" 2>&1)
  
  # Verify toggle-cd set cd-look=1 (not cd-hook=1)
  if ! grep -q "^cd-look=1$" "$test_spellbook/.mud"; then
    TEST_FAILURE_REASON="toggle-cd did not set cd-look=1 in config"
    return 1
  fi
  
  # Make sure it didn't set cd-hook=1
  if grep -q "^cd-hook=1$" "$test_spellbook/.mud"; then
    TEST_FAILURE_REASON="toggle-cd set cd-hook=1, but it should set cd-look=1"
    return 1
  fi
  
  return 0
}

test_install_cd_sets_cd_look() {
  skip-if-compiled || return $?
  
  # Create temporary spellbook directory
  tmpdir=$(make_tempdir)
  test_spellbook="$tmpdir/.spellbook"
  mkdir -p "$test_spellbook"
  
  # Install cd hook using install-cd
  output=$(env SPELLBOOK_DIR="$test_spellbook" sh "$ROOT_DIR/spells/.arcana/mud/install-cd" 2>&1)
  
  # Verify install-cd set cd-look=1 (not cd-hook=1)
  if ! grep -q "^cd-look=1$" "$test_spellbook/.mud"; then
    TEST_FAILURE_REASON="install-cd did not set cd-look=1 in config"
    return 1
  fi
  
  # Make sure it didn't set cd-hook=1
  if grep -q "^cd-hook=1$" "$test_spellbook/.mud"; then
    TEST_FAILURE_REASON="install-cd set cd-hook=1, but it should set cd-look=1"
    return 1
  fi
  
  return 0
}

run_test_case "cd-hook imp exists and is executable" test_cd_hook_exists
run_test_case "cd-hook runs without config file" test_cd_hook_runs_without_config
run_test_case "cd-hook runs with config file" test_cd_hook_with_config
run_test_case "invoke-wizardry checks for cd-look=1 config key" test_invoke_wizardry_checks_correct_config_key
run_test_case "toggle-cd sets cd-look=1 config key" test_toggle_cd_sets_cd_look
run_test_case "install-cd sets cd-look=1 config key" test_install_cd_sets_cd_look
finish_tests
