#!/bin/sh
# Comprehensive tests for chat-cleanup-inactive-avatars

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Setup test environment
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

# Test: Recent avatar is NOT deleted
test_cleanup_recent_avatar_preserved() {
  setup_test_env
  
  room_dir="$CHAT_DIR/testroom"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Create recent avatar with current timestamp
  avatar_dir="$room_dir/.recentuser"
  mkdir -p "$avatar_dir"
  touch "$avatar_dir/.web_avatar"
  current_time=$(date +%s)
  printf '%s\n' "$current_time" > "$avatar_dir/.last_activity"
  
  # Run cleanup
  chat-cleanup-inactive-avatars "$room_dir"
  
  # Avatar should still exist
  if [ ! -d "$avatar_dir" ]; then
    cleanup_test_env
    TEST_FAILURE_REASON="Recent avatar was deleted but should be preserved"
    return 1
  fi
  
  cleanup_test_env
  return 0
}

# Test: Old avatar IS deleted
test_cleanup_old_avatar_deleted() {
  setup_test_env
  
  room_dir="$CHAT_DIR/testroom"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Create old avatar (31 minutes ago = 1860 seconds)
  avatar_dir="$room_dir/.olduser"
  mkdir -p "$avatar_dir"
  touch "$avatar_dir/.web_avatar"
  current_time=$(date +%s)
  old_time=$((current_time - 1860))
  printf '%s\n' "$old_time" > "$avatar_dir/.last_activity"
  
  # Run cleanup
  chat-cleanup-inactive-avatars "$room_dir"
  
  # Avatar should be deleted
  if [ -d "$avatar_dir" ]; then
    cleanup_test_env
    TEST_FAILURE_REASON="Old avatar should be deleted but still exists"
    return 1
  fi
  
  cleanup_test_env
  return 0
}

# Test: MUD avatar (no web_avatar flag) is NOT deleted
test_cleanup_mud_avatar_preserved() {
  setup_test_env
  
  room_dir="$CHAT_DIR/testroom"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Create MUD avatar (no web_avatar attribute, old timestamp)
  avatar_dir="$room_dir/.muduser"
  mkdir -p "$avatar_dir"
  # Don't set web_avatar attribute
  current_time=$(date +%s)
  old_time=$((current_time - 3600))  # 1 hour old
  printf '%s\n' "$old_time" > "$avatar_dir/.last_activity"
  
  # Run cleanup
  chat-cleanup-inactive-avatars "$room_dir"
  
  # MUD avatar should NOT be deleted
  if [ ! -d "$avatar_dir" ]; then
    cleanup_test_env
    TEST_FAILURE_REASON="MUD avatar should not be deleted"
    return 1
  fi
  
  cleanup_test_env
  return 0
}

# Test: Avatar at exactly 30 minutes is NOT deleted (boundary case)
test_cleanup_boundary_30min_preserved() {
  setup_test_env
  
  room_dir="$CHAT_DIR/testroom"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Create avatar at exactly 30 minutes (1800 seconds)
  avatar_dir="$room_dir/.boundaryuser"
  mkdir -p "$avatar_dir"
  touch "$avatar_dir/.web_avatar"
  current_time=$(date +%s)
  boundary_time=$((current_time - 1800))
  printf '%s\n' "$boundary_time" > "$avatar_dir/.last_activity"
  
  # Run cleanup
  chat-cleanup-inactive-avatars "$room_dir"
  
  # Avatar at exactly 30 min should NOT be deleted (> threshold, not >=)
  if [ ! -d "$avatar_dir" ]; then
    cleanup_test_env
    TEST_FAILURE_REASON="Avatar at exactly 30 minutes should be preserved"
    return 1
  fi
  
  cleanup_test_env
  return 0
}

# Test: Mixed avatars - only old web avatars deleted
test_cleanup_mixed_avatars() {
  setup_test_env
  
  room_dir="$CHAT_DIR/testroom"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  current_time=$(date +%s)
  
  # Create recent web avatar
  recent_dir="$room_dir/.recent"
  mkdir -p "$recent_dir"
  touch "$recent_dir/.web_avatar"
  printf '%s\n' "$current_time" > "$recent_dir/.last_activity"
  
  # Create old web avatar
  old_dir="$room_dir/.old"
  mkdir -p "$old_dir"
  touch "$old_dir/.web_avatar"
  old_time=$((current_time - 1860))
  printf '%s\n' "$old_time" > "$old_dir/.last_activity"
  
  # Create old MUD avatar
  mud_dir="$room_dir/.mud"
  mkdir -p "$mud_dir"
  # No .web_avatar file (MUD avatar)
  printf '%s\n' "$old_time" > "$mud_dir/.last_activity"
  
  # Run cleanup
  chat-cleanup-inactive-avatars "$room_dir"
  
  # Check results
  if [ ! -d "$recent_dir" ]; then
    cleanup_test_env
    TEST_FAILURE_REASON="Recent web avatar should be preserved"
    return 1
  fi
  
  if [ -d "$old_dir" ]; then
    cleanup_test_env
    TEST_FAILURE_REASON="Old web avatar should be deleted"
    return 1
  fi
  
  if [ ! -d "$mud_dir" ]; then
    cleanup_test_env
    TEST_FAILURE_REASON="Old MUD avatar should be preserved"
    return 1
  fi
  
  cleanup_test_env
  return 0
}

# Test: Fallback to directory mtime when no last_activity attribute
test_cleanup_fallback_to_mtime() {
  setup_test_env
  
  room_dir="$CHAT_DIR/testroom"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Create avatar without last_activity attribute (old directory)
  avatar_dir="$room_dir/.noattr"
  mkdir -p "$avatar_dir"
  touch "$avatar_dir/.web_avatar"
  # Don't set last_activity - should fall back to mtime
  # Make directory appear old
  touch -t 202001010000 "$avatar_dir" 2>/dev/null || true
  
  # Run cleanup
  chat-cleanup-inactive-avatars "$room_dir"
  
  # Avatar should be deleted based on mtime fallback
  if [ -d "$avatar_dir" ]; then
    cleanup_test_env
    TEST_FAILURE_REASON="Avatar with old mtime should be deleted"
    return 1
  fi
  
  cleanup_test_env
  return 0
}

# Run all tests
run_test_case "Cleanup: recent avatar preserved" test_cleanup_recent_avatar_preserved
run_test_case "Cleanup: old avatar deleted" test_cleanup_old_avatar_deleted
run_test_case "Cleanup: MUD avatar preserved" test_cleanup_mud_avatar_preserved
run_test_case "Cleanup: 30min boundary preserved" test_cleanup_boundary_30min_preserved
run_test_case "Cleanup: mixed avatars handled correctly" test_cleanup_mixed_avatars
run_test_case "Cleanup: fallback to mtime works" test_cleanup_fallback_to_mtime

finish_tests
