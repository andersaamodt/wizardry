#!/bin/sh
# Comprehensive tests for chat-list-avatars CGI script

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Create a temporary test environment
setup_test_env() {
  test_tmpdir=$(mktemp -d)
  export WIZARDRY_SITES_DIR="$test_tmpdir/sites"
  CHAT_DIR="$WIZARDRY_SITES_DIR/.sitedata/default/chatrooms"
  export WIZARDRY_SITE_NAME=""
}

cleanup_test_env() {
  if [ -n "${test_tmpdir:-}" ] && [ -d "$test_tmpdir" ]; then
    rm -rf "$test_tmpdir"
  fi
  unset WIZARDRY_SITES_DIR
  unset WIZARDRY_SITE_NAME
}

# Test: List avatars in empty room
test_list_avatars_empty_room() {
  setup_test_env
  
  # Create room with no avatars
  room_name="test-empty-room"
  room_dir="$CHAT_DIR/$room_name"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Run chat-list-avatars
  export QUERY_STRING="room=$room_name"
  output=$(chat-list-avatars 2>&1)
  status=$?
  
  cleanup_test_env
  
  # Check output
  if [ $status -ne 0 ]; then
    TEST_FAILURE_REASON="Script failed with status $status"
    return 1
  fi
  
  # Extract JSON (skip HTTP headers)
  json=$(printf '%s' "$output" | sed -n '/^{/,$p')
  
  # Should return empty array
  if ! printf '%s' "$json" | grep -q '{"avatars": \[\]}'; then
    TEST_FAILURE_REASON="Expected empty avatars array, got: $json"
    return 1
  fi
  
  return 0
}

# Test: List avatars with one avatar
test_list_avatars_one_avatar() {
  setup_test_env
  
  # Create room with one avatar
  room_name="test-one-avatar"
  room_dir="$CHAT_DIR/$room_name"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Create avatar directory
  avatar_dir="$room_dir/.testuser"
  mkdir -p "$avatar_dir"
  
  # Mark as web avatar (may fail if xattr not supported)
  set-attribute "user.web_avatar" "1" "$avatar_dir" 2>/dev/null || true
  
  # Run chat-list-avatars
  export QUERY_STRING="room=$room_name"
  output=$(chat-list-avatars 2>&1)
  status=$?
  
  cleanup_test_env
  
  # Check output
  if [ $status -ne 0 ]; then
    TEST_FAILURE_REASON="Script failed with status $status"
    return 1
  fi
  
  # Extract JSON
  json=$(printf '%s' "$output" | sed -n '/^{/,$p')
  
  # Should return array with one avatar
  if ! printf '%s' "$json" | grep -q '"username": "testuser"'; then
    TEST_FAILURE_REASON="Expected testuser in output, got: $json"
    return 1
  fi
  
  return 0
}

# Test: List avatars with multiple avatars
test_list_avatars_multiple_avatars() {
  setup_test_env
  
  # Create room with multiple avatars
  room_name="test-multi-avatar"
  room_dir="$CHAT_DIR/$room_name"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Create multiple avatar directories
  for user in alice bob charlie; do
    avatar_dir="$room_dir/.$user"
    mkdir -p "$avatar_dir"
    set-attribute "user.web_avatar" "1" "$avatar_dir" 2>/dev/null || true
  done
  
  # Run chat-list-avatars
  export QUERY_STRING="room=$room_name"
  output=$(chat-list-avatars 2>&1)
  status=$?
  
  cleanup_test_env
  
  # Check output
  if [ $status -ne 0 ]; then
    TEST_FAILURE_REASON="Script failed with status $status"
    return 1
  fi
  
  # Extract JSON
  json=$(printf '%s' "$output" | sed -n '/^{/,$p')
  
  # Should return array with all three avatars
  for user in alice bob charlie; do
    if ! printf '%s' "$json" | grep -q "\"username\": \"$user\""; then
      TEST_FAILURE_REASON="Expected $user in output, got: $json"
      return 1
    fi
  done
  
  return 0
}

# Test: Mixed web and MUD avatars
test_list_avatars_mixed_types() {
  setup_test_env
  
  # Create room
  room_name="test-mixed"
  room_dir="$CHAT_DIR/$room_name"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Create web avatar
  web_avatar="$room_dir/.webuser"
  mkdir -p "$web_avatar"
  set-attribute "user.web_avatar" "1" "$web_avatar" 2>/dev/null || true
  
  # Create MUD avatar (no web_avatar attribute)
  mud_avatar="$room_dir/.muduser"
  mkdir -p "$mud_avatar"
  
  # Run chat-list-avatars
  export QUERY_STRING="room=$room_name"
  output=$(chat-list-avatars 2>&1)
  status=$?
  
  cleanup_test_env
  
  # Check output
  if [ $status -ne 0 ]; then
    TEST_FAILURE_REASON="Script failed with status $status"
    return 1
  fi
  
  # Extract JSON
  json=$(printf '%s' "$output" | sed -n '/^{/,$p')
  
  # Should have both users
  if ! printf '%s' "$json" | grep -q '"username": "webuser"'; then
    TEST_FAILURE_REASON="Expected webuser in output, got: $json"
    return 1
  fi
  
  if ! printf '%s' "$json" | grep -q '"username": "muduser"'; then
    TEST_FAILURE_REASON="Expected muduser in output, got: $json"
    return 1
  fi
  
  return 0
}

# Test: Room not found
test_list_avatars_room_not_found() {
  setup_test_env
  
  # Don't create the room
  room_name="nonexistent-room"
  
  # Run chat-list-avatars
  export QUERY_STRING="room=$room_name"
  output=$(chat-list-avatars 2>&1)
  status=$?
  
  cleanup_test_env
  
  # Check output
  if [ $status -ne 0 ]; then
    TEST_FAILURE_REASON="Script failed with status $status"
    return 1
  fi
  
  # Extract JSON
  json=$(printf '%s' "$output" | sed -n '/^{/,$p')
  
  # Should return error
  if ! printf '%s' "$json" | grep -q '{"error": "Room not found"}'; then
    TEST_FAILURE_REASON="Expected error message, got: $json"
    return 1
  fi
  
  return 0
}

# Test: No room name provided
test_list_avatars_no_room_name() {
  setup_test_env
  
  # Run chat-list-avatars with empty query string
  export QUERY_STRING=""
  output=$(chat-list-avatars 2>&1)
  status=$?
  
  cleanup_test_env
  
  # Check output
  if [ $status -ne 0 ]; then
    TEST_FAILURE_REASON="Script failed with status $status"
    return 1
  fi
  
  # Extract JSON
  json=$(printf '%s' "$output" | sed -n '/^{/,$p')
  
  # Should return error
  if ! printf '%s' "$json" | grep -q '{"error": "Room name required"}'; then
    TEST_FAILURE_REASON="Expected error message, got: $json"
    return 1
  fi
  
  return 0
}

# Test: Avatars are NOT deleted by cleanup logic for recent activity
test_list_avatars_no_cleanup_recent() {
  setup_test_env
  
  # Create room with recent avatar
  room_name="test-cleanup"
  room_dir="$CHAT_DIR/$room_name"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Create web avatar (just created, so very recent)
  avatar_dir="$room_dir/.recentuser"
  mkdir -p "$avatar_dir"
  set-attribute "user.web_avatar" "1" "$avatar_dir" 2>/dev/null || true
  
  # Run chat-list-avatars (should NOT delete recent avatar)
  export QUERY_STRING="room=$room_name"
  output=$(chat-list-avatars 2>&1)
  status=$?
  
  cleanup_test_env
  
  # Check output
  if [ $status -ne 0 ]; then
    TEST_FAILURE_REASON="Script failed with status $status"
    return 1
  fi
  
  # Extract JSON
  json=$(printf '%s' "$output" | sed -n '/^{/,$p')
  
  # Should still have the avatar
  if ! printf '%s' "$json" | grep -q '"username": "recentuser"'; then
    TEST_FAILURE_REASON="Recent avatar should not be deleted, got: $json"
    return 1
  fi
  
  return 0
}

# Run all tests
run_test_case "List avatars: empty room" test_list_avatars_empty_room
run_test_case "List avatars: one avatar" test_list_avatars_one_avatar
run_test_case "List avatars: multiple avatars" test_list_avatars_multiple_avatars
run_test_case "List avatars: mixed web and MUD avatars" test_list_avatars_mixed_types
run_test_case "List avatars: room not found" test_list_avatars_room_not_found
run_test_case "List avatars: no room name" test_list_avatars_no_room_name
run_test_case "List avatars: no cleanup of recent avatars" test_list_avatars_no_cleanup_recent

finish_tests
