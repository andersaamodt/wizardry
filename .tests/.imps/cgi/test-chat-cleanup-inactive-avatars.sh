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
  enchant "$avatar_dir" "web_avatar=1" 2>/dev/null || true
  current_time=$(date +%s)
  enchant "$avatar_dir" "last_activity=$current_time" 2>/dev/null || true
  
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
  
  # Create old avatar (6 minutes ago = 360 seconds)
  avatar_dir="$room_dir/.olduser"
  mkdir -p "$avatar_dir"
  enchant "$avatar_dir" "web_avatar=1" 2>/dev/null || true
  current_time=$(date +%s)
  old_time=$((current_time - 360))
  enchant "$avatar_dir" "last_activity=$old_time" 2>/dev/null || true
  # Set directory mtime to old time (fallback when xattr not available)
  touch -t 202001010000 "$avatar_dir" 2>/dev/null || true
  
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

# Test: Avatar at exactly 5 minutes is NOT deleted (boundary case)
test_cleanup_boundary_5min_preserved() {
  setup_test_env
  
  room_dir="$CHAT_DIR/testroom"
  mkdir -p "$room_dir"
  touch "$room_dir/.log"
  
  # Create avatar at exactly 5 minutes (300 seconds)
  avatar_dir="$room_dir/.boundaryuser"
  mkdir -p "$avatar_dir"
  enchant "$avatar_dir" "web_avatar=1" 2>/dev/null || true
  current_time=$(date +%s)
  boundary_time=$((current_time - 300))
  enchant "$avatar_dir" "last_activity=$boundary_time" 2>/dev/null || true
  
  # Run cleanup
  chat-cleanup-inactive-avatars "$room_dir"
  
  # Avatar at exactly 5 min should NOT be deleted (> threshold, not >=)
  if [ ! -d "$avatar_dir" ]; then
    cleanup_test_env
    TEST_FAILURE_REASON="Avatar at exactly 5 minutes should be preserved"
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
  enchant "$recent_dir" "web_avatar=1" 2>/dev/null || true
  enchant "$recent_dir" "last_activity=$current_time" 2>/dev/null || true
  
  # Create old web avatar
  old_dir="$room_dir/.old"
  mkdir -p "$old_dir"
  enchant "$old_dir" "web_avatar=1" 2>/dev/null || true
  old_time=$((current_time - 360))
  enchant "$old_dir" "last_activity=$old_time" 2>/dev/null || true
  # Set directory mtime to old time (fallback when xattr not available)
  touch -t 202001010000 "$old_dir" 2>/dev/null || true
  
  # Create old MUD avatar (has is_avatar attribute)
  mud_dir="$room_dir/.mud"
  mkdir -p "$mud_dir"
  # MUD avatars have is_avatar=1 set
  enchant "$mud_dir" "is_avatar=1" 2>/dev/null || true
  enchant "$mud_dir" "last_activity=$old_time" 2>/dev/null || true
  
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
  enchant "$avatar_dir" "web_avatar=1" 2>/dev/null || true
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
run_test_case "Cleanup: 5min boundary preserved" test_cleanup_boundary_5min_preserved
run_test_case "Cleanup: mixed avatars handled correctly" test_cleanup_mixed_avatars
run_test_case "Cleanup: fallback to mtime works" test_cleanup_fallback_to_mtime

finish_tests
