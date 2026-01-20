#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_move_avatar_exists() {
  move_avatar_path="$test_root/spells/.imps/mud/move-avatar"
  [ -f "$move_avatar_path" ] && [ -x "$move_avatar_path" ]
}

test_move_avatar_no_config() {
  # Should not fail if config doesn't exist
  move_avatar_imp="$test_root/spells/.imps/mud/move-avatar"
  output=$("$move_avatar_imp" 2>&1)
  [ $? -eq 0 ]
}

test_move_avatar_no_avatar() {
  # Create config but no avatar folder
  test_dir=$(mktemp -d)
  test_config="$test_dir/.mud"
  printf 'avatar-path=/nonexistent/avatar\n' > "$test_config"
  
  SPELLBOOK_DIR="$test_dir"
  export SPELLBOOK_DIR
  
  run_sourced_spell ".imps/mud/move-avatar"
  assert_success
  
  rm -rf "$test_dir"
}

test_move_avatar_moves_folder() {
  # Create a test avatar that can be moved
  test_dir=$(mktemp -d)
  avatar_dir="$test_dir/.testuser"
  mkdir "$avatar_dir"
  touch "$avatar_dir/item.txt"
  
  test_config="$test_dir/.mud"
  printf 'avatar-path=%s\n' "$avatar_dir" > "$test_config"
  
  # Move to a different directory
  new_dir=$(mktemp -d)
  orig_pwd=$PWD
  cd "$new_dir" || return 1
  
  SPELLBOOK_DIR="$test_dir"
  export SPELLBOOK_DIR
  
  # Source the imp directly (it needs to run in current shell to get PWD)
  move_avatar_imp="$test_root/spells/.imps/mud/move-avatar"
  . "$move_avatar_imp" || {
    cd "$orig_pwd" || true
    rm -rf "$test_dir" "$new_dir"
    return 1
  }
  
  # Check avatar moved (it should now be in new_dir)
  cd "$orig_pwd" || return 1
  
  # Debug: show what's in new_dir
  if [ ! -d "$new_dir/.testuser" ]; then
    TEST_FAILURE_REASON="Avatar directory $new_dir/.testuser does not exist after move"
    rm -rf "$test_dir" "$new_dir"
    return 1
  fi
  
  if [ ! -f "$new_dir/.testuser/item.txt" ]; then
    TEST_FAILURE_REASON="File $new_dir/.testuser/item.txt missing (dir exists but empty)"
    rm -rf "$test_dir" "$new_dir"
    return 1
  fi
  
  rm -rf "$test_dir" "$new_dir"
  return 0
}

run_test_case "move-avatar imp exists and is executable" test_move_avatar_exists
run_test_case "move-avatar handles missing config" test_move_avatar_no_config
run_test_case "move-avatar handles missing avatar" test_move_avatar_no_avatar
run_test_case "move-avatar moves avatar folder" test_move_avatar_moves_folder
finish_tests
