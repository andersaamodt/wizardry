#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_rename_avatar() {
  # Create test environment
  test_dir=$(mktemp -d)
  room_dir="$test_dir/chatrooms/TestRoom"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Create old avatar
  old_avatar="$room_dir/.OldName"
  mkdir -p "$old_avatar"
  
  # Mark as web avatar
  enchant "$old_avatar" web_avatar 1 2>/dev/null || true
  
  # Set up environment for CGI
  REQUEST_METHOD="POST"
  WIZARDRY_SITES_DIR="$test_dir"
  WIZARDRY_SITE_NAME="default"
  export REQUEST_METHOD WIZARDRY_SITES_DIR WIZARDRY_SITE_NAME
  
  # Prepare POST data
  post_data="room=TestRoom&old_user=OldName&new_user=NewName"
  
  # Run chat-rename-avatar
  result=$(printf '%s' "$post_data" | spells/.imps/cgi/chat-rename-avatar)
  
  # Check avatar was renamed
  success=0
  [ ! -d "$old_avatar" ] && [ -d "$room_dir/.NewName" ] && \
  grep -q "changed their name" "$room_dir/.log" && success=1
  
  rm -rf "$test_dir"
  [ "$success" -eq 1 ]
}

test_rename_avatar_logs_message() {
  # Create test environment
  test_dir=$(mktemp -d)
  room_dir="$test_dir/chatrooms/TestRoom"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Create old avatar
  old_avatar="$room_dir/.Alice"
  mkdir -p "$old_avatar"
  
  # Set up environment for CGI
  REQUEST_METHOD="POST"
  WIZARDRY_SITES_DIR="$test_dir"
  WIZARDRY_SITE_NAME="default"
  export REQUEST_METHOD WIZARDRY_SITES_DIR WIZARDRY_SITE_NAME
  
  # Prepare POST data
  post_data="room=TestRoom&old_user=Alice&new_user=Bob"
  
  # Run chat-rename-avatar
  result=$(printf '%s' "$post_data" | spells/.imps/cgi/chat-rename-avatar)
  
  # Check log contains the name change message
  success=0
  grep -q "Alice changed their name to Bob" "$room_dir/.log" && success=1
  
  rm -rf "$test_dir"
  [ "$success" -eq 1 ]
}

test_rename_prevents_duplicate_messages() {
  # Create test environment
  test_dir=$(mktemp -d)
  room_dir="$test_dir/chatrooms/TestRoom"
  mkdir -p "$room_dir"
  
  # Add an existing name change message
  printf '%s\n' "[12:00] log: Alice changed their name to Bob." > "$room_dir/.log"
  
  # Create avatar
  mkdir -p "$room_dir/.Alice"
  
  # Set up environment for CGI
  REQUEST_METHOD="POST"
  WIZARDRY_SITES_DIR="$test_dir"
  WIZARDRY_SITE_NAME="default"
  export REQUEST_METHOD WIZARDRY_SITES_DIR WIZARDRY_SITE_NAME
  
  # Try to log the same name change again
  post_data="room=TestRoom&old_user=Alice&new_user=Bob"
  result=$(printf '%s' "$post_data" | spells/.imps/cgi/chat-rename-avatar)
  
  # Should only appear once in log (duplicate detection)
  count=$(grep -c "Alice changed their name to Bob" "$room_dir/.log")
  success=0
  [ "$count" = "1" ] && success=1
  
  rm -rf "$test_dir"
  [ "$success" -eq 1 ]
}

run_test_case "renames avatar directory" test_rename_avatar
run_test_case "logs name change message" test_rename_avatar_logs_message
run_test_case "prevents duplicate name change messages" test_rename_prevents_duplicate_messages

finish_tests
