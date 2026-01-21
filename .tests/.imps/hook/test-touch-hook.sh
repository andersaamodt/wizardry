#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_touch_hook_exists() {
  touch_hook_path="$test_root/spells/.imps/hook/touch-hook"
  [ -f "$touch_hook_path" ] && [ -x "$touch_hook_path" ]
}

test_touch_hook_runs_without_config() {
  # Should not fail even if config doesn't exist
  touch_hook_imp="$test_root/spells/.imps/hook/touch-hook"
  output=$("$touch_hook_imp" "test.txt" 2>&1)
  [ $? -eq 0 ]
}

test_touch_hook_with_config() {
  # Create a test config
  test_dir=$(mktemp -d)
  test_config="$test_dir/.mud/config"
  mkdir -p "$test_dir/.mud"
  printf 'touch-hook=0\n' > "$test_config"
  
  SPELLBOOK_DIR="$test_dir"
  export SPELLBOOK_DIR
  
  touch_hook_imp="$test_root/spells/.imps/hook/touch-hook"
  output=$("$touch_hook_imp" "test.txt" 2>&1)
  result=$?
  
  rm -rf "$test_dir"
  [ $result -eq 0 ]
}

run_test_case "touch-hook imp exists and is executable" test_touch_hook_exists
run_test_case "touch-hook runs without config file" test_touch_hook_runs_without_config
run_test_case "touch-hook runs with config file" test_touch_hook_with_config
finish_tests
