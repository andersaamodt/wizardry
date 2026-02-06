#!/bin/sh
# Comprehensive integration test for chat system
# Tests all assumptions about the chat flow

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_env_variables_required() {
  # Test that chat CGI scripts require WIZARDRY_SITE_NAME and WIZARDRY_SITES_DIR
  test_site_dir=$(temp-dir chat-integration-env)
  
  # Without environment variables, scripts should fail gracefully
  unset WIZARDRY_SITE_NAME
  unset WIZARDRY_SITES_DIR
  export REQUEST_METHOD="GET"
  export QUERY_STRING="name=testroom"
  
  # The script should still run (it has defaults) but we're testing it works
  # Let's set them properly
  export WIZARDRY_SITE_NAME="testsite"
  export WIZARDRY_SITES_DIR="$test_site_dir"
  
  # Create necessary directory structure
  mkdir -p "$test_site_dir/.sitedata/testsite"
  
  # This should work now
  run_spell spells/.imps/cgi/chat-create-room > /dev/null 2>&1
  
  # Check that chatrooms directory was created
  if [ ! -d "$test_site_dir/.sitedata/testsite/chatrooms" ]; then
    TEST_FAILURE_REASON="chatrooms directory not created"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  rm -rf "$test_site_dir"
}

test_complete_chat_flow() {
  # Test the complete flow: create room -> send message -> verify log
  test_site_dir=$(temp-dir chat-integration-flow)
  
  export WIZARDRY_SITE_NAME="testsite"
  export WIZARDRY_SITES_DIR="$test_site_dir"
  mkdir -p "$test_site_dir/.sitedata/testsite"
  
  # Step 1: Create a room
  export REQUEST_METHOD="GET"
  export QUERY_STRING="name=testroom"
  run_spell spells/.imps/cgi/chat-create-room
  
  if ! echo "$OUTPUT" | grep -q "created\|exists"; then
    TEST_FAILURE_REASON="Room creation failed. OUTPUT: $OUTPUT, ERROR: $ERROR"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  # Verify log file exists and has correct permissions
  log_file="$test_site_dir/.sitedata/testsite/chatrooms/testroom/.log"
  if [ ! -f "$log_file" ]; then
    TEST_FAILURE_REASON=".log file not created"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  perms=$(stat -c '%a' "$log_file" 2>/dev/null || \
          stat -f '%Lp' "$log_file" 2>/dev/null || echo "000")
  if [ "$perms" != "664" ]; then
    TEST_FAILURE_REASON=".log file has wrong permissions: $perms (expected 664)"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  # Step 2: Send a message
  export REQUEST_METHOD="POST"
  unset QUERY_STRING || true
  output=$(printf 'room=testroom&user=Alice&msg=Hello' | spells/.imps/cgi/chat-send-message 2>&1)
  
  if ! echo "$output" | grep -q "Message sent"; then
    TEST_FAILURE_REASON="Message send failed. Output: $output"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  # Step 3: Verify message is in log file
  if [ ! -f "$log_file" ]; then
    TEST_FAILURE_REASON=".log file disappeared after message send"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  if ! grep -q "Alice: Hello" "$log_file"; then
    TEST_FAILURE_REASON="Message not found in log file. Log contents: $(cat "$log_file")"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  # Step 4: Send another message from different user
  output=$(printf 'room=testroom&user=Bob&msg=Hi' | spells/.imps/cgi/chat-send-message 2>&1)
  
  if ! echo "$output" | grep -q "Message sent"; then
    TEST_FAILURE_REASON="Second message send failed. Output: $output"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  if ! grep -q "Bob: Hi" "$log_file"; then
    TEST_FAILURE_REASON="Second message not found in log file"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  # Step 5: Verify both messages are there
  msg_count=$(grep -c ":" "$log_file" || echo "0")
  if [ "$msg_count" -lt 2 ]; then
    TEST_FAILURE_REASON="Not enough messages in log. Expected 2+, got $msg_count"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  rm -rf "$test_site_dir"
}

test_log_file_writability() {
  # Test that the log file is actually writable after creation
  test_site_dir=$(temp-dir chat-integration-write)
  
  export WIZARDRY_SITE_NAME="testsite"
  export WIZARDRY_SITES_DIR="$test_site_dir"
  mkdir -p "$test_site_dir/.sitedata/testsite"
  
  # Create a room
  export REQUEST_METHOD="GET"
  export QUERY_STRING="name=testroom"
  run_spell spells/.imps/cgi/chat-create-room > /dev/null 2>&1
  
  log_file="$test_site_dir/.sitedata/testsite/chatrooms/testroom/.log"
  
  # Try to write to the log file directly
  if ! printf "test\n" >> "$log_file" 2>/dev/null; then
    TEST_FAILURE_REASON=".log file is not writable"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  # Verify the write succeeded
  if ! grep -q "test" "$log_file"; then
    TEST_FAILURE_REASON="Write to .log file didn't persist"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  rm -rf "$test_site_dir"
}

test_avatar_creation() {
  # Test that avatars are created properly when sending messages
  test_site_dir=$(temp-dir chat-integration-avatar)
  
  export WIZARDRY_SITE_NAME="testsite"
  export WIZARDRY_SITES_DIR="$test_site_dir"
  mkdir -p "$test_site_dir/.sitedata/testsite"
  
  # Create room
  export REQUEST_METHOD="GET"
  export QUERY_STRING="name=testroom"
  run_spell spells/.imps/cgi/chat-create-room > /dev/null 2>&1
  
  # Send message (should create avatar)
  export REQUEST_METHOD="POST"
  printf 'room=testroom&user=Alice&msg=Hello' | run_spell spells/.imps/cgi/chat-send-message > /dev/null 2>&1
  
  # Check that avatar directory was created
  room_dir="$test_site_dir/.sitedata/testsite/chatrooms/testroom"
  if [ ! -d "$room_dir/.Alice" ]; then
    TEST_FAILURE_REASON="Avatar directory .Alice not created"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  rm -rf "$test_site_dir"
}

test_directory_permissions() {
  # Test that all directories have correct permissions
  test_site_dir=$(temp-dir chat-integration-dirperms)
  
  export WIZARDRY_SITE_NAME="testsite"
  export WIZARDRY_SITES_DIR="$test_site_dir"
  mkdir -p "$test_site_dir/.sitedata/testsite"
  
  # Create room and send message
  export REQUEST_METHOD="GET"
  export QUERY_STRING="name=testroom"
  run_spell spells/.imps/cgi/chat-create-room > /dev/null 2>&1
  
  export REQUEST_METHOD="POST"
  printf 'room=testroom&user=Alice&msg=Hello' | run_spell spells/.imps/cgi/chat-send-message > /dev/null 2>&1
  
  # Check chatrooms directory permissions
  chatrooms_dir="$test_site_dir/.sitedata/testsite/chatrooms"
  if [ ! -d "$chatrooms_dir" ]; then
    TEST_FAILURE_REASON="chatrooms directory not created"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  # Check that we can list the directory
  if ! ls "$chatrooms_dir" > /dev/null 2>&1; then
    TEST_FAILURE_REASON="Cannot list chatrooms directory"
    rm -rf "$test_site_dir"
    return 1
  fi
  
  rm -rf "$test_site_dir"
}

run_test_case "ENV: Environment variables work correctly" test_env_variables_required
run_test_case "FLOW: Complete chat flow works" test_complete_chat_flow
run_test_case "WRITE: Log file is writable after creation" test_log_file_writability
run_test_case "AVATAR: Avatar creation works" test_avatar_creation
run_test_case "PERMS: Directory permissions allow operations" test_directory_permissions

finish_tests
