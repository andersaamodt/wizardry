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
  printf '%s' "$output" | grep -q '"moved":true'
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
  printf '%s' "$output" | grep -q '"success":true'
}

# Test invalid username rejected
test_move_rejects_invalid_username() {
  setup_test_env
  
  mkdir -p "$SPELLBOOK_DIR/room1" "$SPELLBOOK_DIR/room2"
  
  output=$(printf '{"room":"room2","username":"test@user","oldRoom":"room1"}' | chat-move-avatar 2>&1)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q '"error"' && \
  printf '%s' "$output" | grep -q 'invalid characters'
}

# Run tests using the test framework pattern
test_move_avatar_success
test_move_creates_when_no_old_avatar
test_move_rejects_invalid_username

printf "All chat-move-avatar tests passed\n"
