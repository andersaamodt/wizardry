#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Setup test environment
setup_test_env() {
  test_tmpdir=$(mktemp -d)
  export SPELLBOOK_DIR="$test_tmpdir/spellbook"
  mkdir -p "$SPELLBOOK_DIR"
}

# Cleanup test environment
cleanup_test_env() {
  if [ -n "${test_tmpdir:-}" ] && [ -d "$test_tmpdir" ]; then
    rm -rf "$test_tmpdir"
  fi
  unset SPELLBOOK_DIR
}

test_chat_move_avatar_exists() {
  [ -x "spells/.imps/cgi/chat-move-avatar" ]
}

# Test moving avatar between rooms
test_move_avatar_success() {
  setup_test_env
  
  # Create old room with avatar
  old_room="$SPELLBOOK_DIR/oldroom"
  new_room="$SPELLBOOK_DIR/newroom"
  mkdir -p "$old_room" "$new_room"
  touch "$old_room/.log" "$new_room/.log"
  
  # Create avatar in old room
  mkdir -p "$old_room/.testuser"
  
  # Move avatar
  output=$(printf '{"room":"newroom","username":"testuser","oldRoom":"oldroom"}' | chat-move-avatar 2>&1)
  result=$?
  
  cleanup_test_env
  
  [ "$result" -eq 0 ] && \
  printf '%s' "$output" | grep -q '"success":true' && \
  printf '%s' "$output" | grep -q '"moved":true' && \
  printf '%s' "$output" | grep -q 'Status: 200 OK'
}

# Test creating avatar when no old avatar exists
test_move_creates_when_no_old_avatar() {
  setup_test_env
  
  # Create rooms but no avatar
  old_room="$SPELLBOOK_DIR/oldroom"
  new_room="$SPELLBOOK_DIR/newroom"
  mkdir -p "$old_room" "$new_room"
  touch "$old_room/.log" "$new_room/.log"
  
  # Try to move non-existent avatar
  output=$(printf '{"room":"newroom","username":"testuser","oldRoom":"oldroom"}' | chat-move-avatar 2>&1)
  result=$?
  
  # Check avatar was created
  avatar_exists=0
  [ -d "$new_room/.testuser" ] && avatar_exists=1
  
  cleanup_test_env
  
  [ "$result" -eq 0 ] && \
  [ "$avatar_exists" -eq 1 ] && \
  printf '%s' "$output" | grep -q '"success":true' && \
  printf '%s' "$output" | grep -q 'Status: 200 OK'
}

# Test invalid username rejected
test_move_rejects_invalid_username() {
  setup_test_env
  
  mkdir -p "$SPELLBOOK_DIR/room1" "$SPELLBOOK_DIR/room2"
  
  output=$(printf '{"room":"room2","username":"test@user","oldRoom":"room1"}' | chat-move-avatar 2>&1)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q '"error"' && \
  printf '%s' "$output" | grep -q 'invalid characters' && \
  printf '%s' "$output" | grep -q 'Status: 400 Bad Request'
}

# Test missing parameters rejected with proper status
test_move_rejects_missing_params() {
  setup_test_env
  
  mkdir -p "$SPELLBOOK_DIR/room1"
  
  output=$(printf '{"room":"room1"}' | chat-move-avatar 2>&1)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q '"error"' && \
  printf '%s' "$output" | grep -q 'Missing required parameters' && \
  printf '%s' "$output" | grep -q 'Status: 400 Bad Request'
}

# Test path traversal protection
test_move_rejects_path_traversal() {
  setup_test_env
  
  mkdir -p "$SPELLBOOK_DIR/room1"
  
  output=$(printf '{"room":"../etc/passwd","username":"testuser","oldRoom":"room1"}' | chat-move-avatar 2>&1)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q '"error"' && \
  printf '%s' "$output" | grep -q 'Invalid room name' && \
  printf '%s' "$output" | grep -q 'Status: 400 Bad Request'
}

# Critical test: verify http-status always gets two arguments (the bug fix)
test_http_status_gets_two_args() {
  setup_test_env
  
  mkdir -p "$SPELLBOOK_DIR/room1"
  
  # This should NOT cause "unbound variable" error
  output=$(printf '{"room":"room1"}' | chat-move-avatar 2>&1)
  
  cleanup_test_env
  
  # Should not contain "unbound variable" error
  ! printf '%s' "$output" | grep -q "unbound variable"
}

run_test_case "chat-move-avatar is executable" test_chat_move_avatar_exists
run_test_case "chat-move-avatar moves avatar successfully" test_move_avatar_success
run_test_case "chat-move-avatar creates avatar when old doesn't exist" test_move_creates_when_no_old_avatar
run_test_case "chat-move-avatar rejects invalid username" test_move_rejects_invalid_username
run_test_case "chat-move-avatar rejects missing parameters" test_move_rejects_missing_params
run_test_case "chat-move-avatar rejects path traversal" test_move_rejects_path_traversal
run_test_case "chat-move-avatar always passes two args to http-status" test_http_status_gets_two_args

finish_tests
