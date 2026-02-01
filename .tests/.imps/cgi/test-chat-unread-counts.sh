#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Check if timeout command is available
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_CMD="timeout 1"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_CMD="gtimeout 1"
else
  # No timeout available - use background process with sleep
  TIMEOUT_CMD=""
fi

# Setup test environment
setup_test_env() {
  test_tmpdir=$(mktemp -d)
  export WIZARDRY_SITES_DIR="$test_tmpdir"
  export WIZARDRY_SITE_NAME="default"
  CHAT_DIR="$test_tmpdir/.sitedata/default/chatrooms"
  export CHAT_DIR
}

# Run command with timeout (or background with kill if timeout not available)
run_with_timeout() {
  if [ -n "$TIMEOUT_CMD" ]; then
    $TIMEOUT_CMD "$@" 2>&1 || true
  else
    # Fallback: run in background and kill entire process group after 1 second
    tmpout=$(mktemp)
    "$@" > "$tmpout" 2>&1 &
    pid=$!
    sleep 1
    # Kill entire process group (negative PID) to terminate all child processes
    kill -TERM -- -$pid 2>/dev/null || true
    sleep 0.1  # Give processes time to handle TERM signal
    kill -KILL -- -$pid 2>/dev/null || true  # Force kill if still running
    sleep 0.1
    cat "$tmpout"
    rm -f "$tmpout"
  fi
}

# Cleanup test environment
cleanup_test_env() {
  if [ -n "${test_tmpdir:-}" ] && [ -d "$test_tmpdir" ]; then
    rm -rf "$test_tmpdir"
  fi
  unset WIZARDRY_SITES_DIR
  unset WIZARDRY_SITE_NAME
  unset CHAT_DIR
}

test_chat_unread_counts_exists() {
  [ -x "spells/.imps/cgi/chat-unread-counts" ]
}

test_chat_unread_counts_requires_username() {
  setup_test_env
  
  export QUERY_STRING=""
  output=$(run_with_timeout chat-unread-counts)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "event: error" && \
  printf '%s' "$output" | grep -q "Username required"
}

test_chat_unread_counts_outputs_sse_headers() {
  setup_test_env
  
  export QUERY_STRING="username=testuser"
  output=$(run_with_timeout chat-unread-counts)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "Status: 200 OK" && \
  printf '%s' "$output" | grep -q "Content-Type: text/event-stream"
}

test_chat_unread_counts_sends_json_counts() {
  setup_test_env
  
  # Create rooms with messages
  mkdir -p "$CHAT_DIR/Room1"
  printf "[2024-01-01 10:00:00] Alice: Hello\n" > "$CHAT_DIR/Room1/.log"
  
  mkdir -p "$CHAT_DIR/Room2"
  printf "[2024-01-01 10:00:00] Bob: Hi\n" > "$CHAT_DIR/Room2/.log"
  printf "[2024-01-01 10:01:00] Carol: Hey\n" >> "$CHAT_DIR/Room2/.log"
  
  export QUERY_STRING="username=testuser"
  output=$(run_with_timeout chat-unread-counts)
  
  cleanup_test_env
  
  # Should send counts event with JSON
  printf '%s' "$output" | grep -q "event: counts" && \
  printf '%s' "$output" | grep -q "Room1" && \
  printf '%s' "$output" | grep -q "Room2"
}

test_chat_unread_counts_excludes_log_messages() {
  setup_test_env
  
  # Create room with mix of regular and log messages
  mkdir -p "$CHAT_DIR/TestRoom"
  printf "[2024-01-01 10:00:00] Alice: Hello\n" > "$CHAT_DIR/TestRoom/.log"
  printf "[2024-01-01 10:01:00] log: Bob joined the room\n" >> "$CHAT_DIR/TestRoom/.log"
  printf "[2024-01-01 10:02:00] Carol: Hi\n" >> "$CHAT_DIR/TestRoom/.log"
  
  export QUERY_STRING="username=testuser"
  output=$(run_with_timeout chat-unread-counts)
  
  cleanup_test_env
  
  # Should count 2 messages (excluding log message)
  printf '%s' "$output" | grep -q "event: counts" && \
  printf '%s' "$output" | grep -q '"TestRoom":2'
}

test_chat_unread_counts_handles_empty_room() {
  setup_test_env
  
  # Create empty room
  mkdir -p "$CHAT_DIR/EmptyRoom"
  touch "$CHAT_DIR/EmptyRoom/.log"
  
  export QUERY_STRING="username=testuser"
  output=$(run_with_timeout chat-unread-counts)
  
  cleanup_test_env
  
  # Should send counts with 0 for empty room
  printf '%s' "$output" | grep -q "event: counts" && \
  printf '%s' "$output" | grep -q '"EmptyRoom":0'
}

test_chat_unread_counts_validates_room_names() {
  setup_test_env
  
  # Create room with invalid name (should be skipped)
  mkdir -p "$CHAT_DIR/../invalid"
  printf "[2024-01-01 10:00:00] Test: Message\n" > "$CHAT_DIR/../invalid/.log"
  
  # Create valid room
  mkdir -p "$CHAT_DIR/ValidRoom"
  printf "[2024-01-01 10:00:00] Alice: Hello\n" > "$CHAT_DIR/ValidRoom/.log"
  
  export QUERY_STRING="username=testuser"
  output=$(run_with_timeout chat-unread-counts)
  
  cleanup_test_env
  
  # Should only include ValidRoom, not invalid
  printf '%s' "$output" | grep -q "ValidRoom" && \
  ! printf '%s' "$output" | grep -q "invalid"
}

run_test_case "chat-unread-counts is executable" test_chat_unread_counts_exists
run_test_case "chat-unread-counts requires username" test_chat_unread_counts_requires_username
run_test_case "chat-unread-counts outputs SSE headers" test_chat_unread_counts_outputs_sse_headers
run_test_case "chat-unread-counts sends JSON counts" test_chat_unread_counts_sends_json_counts
run_test_case "chat-unread-counts excludes log messages" test_chat_unread_counts_excludes_log_messages
run_test_case "chat-unread-counts handles empty room" test_chat_unread_counts_handles_empty_room
run_test_case "chat-unread-counts validates room names" test_chat_unread_counts_validates_room_names

finish_tests
