#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_cd_hook_exists() {
  cd_hook_path="$test_root/spells/.imps/hook/cd"
  [ -f "$cd_hook_path" ] && [ -x "$cd_hook_path" ]
}

test_cd_hook_runs_without_config() {
  # Should not fail even if config doesn't exist
  cd_hook_imp="$test_root/spells/.imps/hook/cd"
  output=$("$cd_hook_imp" 2>&1)
  [ $? -eq 0 ]
}

test_cd_hook_with_config() {
  # Create a test config
  test_dir=$(mktemp -d)
  test_config="$test_dir/.mud"
  printf 'cd-hook=0\navatar-enabled=0\n' > "$test_config"
  
  SPELLBOOK_DIR="$test_dir"
  export SPELLBOOK_DIR
  
  cd_hook_imp="$test_root/spells/.imps/hook/cd"
  output=$("$cd_hook_imp" 2>&1)
  result=$?
  
  rm -rf "$test_dir"
  [ $result -eq 0 ]
}

run_test_case "cd-hook imp exists and is executable" test_cd_hook_exists
run_test_case "cd-hook runs without config file" test_cd_hook_runs_without_config
run_test_case "cd-hook runs with config file" test_cd_hook_with_config
finish_tests
