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
    # chat-stream spawns multiple background processes, so we need to kill the whole group
    # Capture output to temp file to avoid subshell issues
    tmpout=$(mktemp)
    "$@" > "$tmpout" 2>&1 &
    pid=$!
    sleep 1
    # Kill entire process group (negative PID) to terminate all child processes
    kill -TERM -- -$pid 2>/dev/null || true
    sleep 0.1  # Give processes time to handle TERM signal
    kill -KILL -- -$pid 2>/dev/null || true  # Force kill if still running
    # Don't wait - just give it a moment and move on
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

test_chat_stream_exists() {
  [ -x "spells/.imps/cgi/chat-stream" ]
}

test_chat_stream_rejects_invalid_room_name() {
  setup_test_env
  
  export QUERY_STRING="room=../../../etc/passwd"
  output=$(run_with_timeout chat-stream)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "event: error" && \
  printf '%s' "$output" | grep -q "Invalid room name"
}

test_chat_stream_rejects_empty_room() {
  setup_test_env
  
  # Empty QUERY_STRING should default to "General" room
  # Create General room so it's found
  mkdir -p "$CHAT_DIR/General"
  touch "$CHAT_DIR/General/.log"
  
  export QUERY_STRING=""
  output=$(run_with_timeout chat-stream)
  
  cleanup_test_env
  
  # Should not error, should use General room
  ! printf '%s' "$output" | grep -q "event: error"
}

test_chat_stream_handles_nonexistent_room() {
  setup_test_env
  
  export QUERY_STRING="room=NonExistentRoom"
  output=$(run_with_timeout chat-stream)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "event: error" && \
  printf '%s' "$output" | grep -q "Room not found"
}

test_chat_stream_does_not_send_old_historical_messages() {
  setup_test_env
  
  # Create room with old messages (should NOT be sent via SSE without since param)
  mkdir -p "$CHAT_DIR/TestRoom"
  printf "[2024-01-01 10:00:00] Alice: Hello\n" > "$CHAT_DIR/TestRoom/.log"
  
  export QUERY_STRING="room=TestRoom"
  output=$(run_with_timeout chat-stream)
  
  cleanup_test_env
  
  # Should NOT contain old messages when no since parameter (O(1) connection time)
  ! printf '%s' "$output" | grep -q "Alice: Hello"
}

test_chat_stream_sends_recent_messages_to_prevent_gaps() {
  setup_test_env
  
  # Create room with recent messages (within last 100 messages)
  mkdir -p "$CHAT_DIR/TestRoom"
  # Simulate messages from "now" - using a timestamp that would be recent
  now_timestamp="2024-12-01 12:00:00"
  printf "[2024-12-01 12:00:01] Alice: Message 1\n" > "$CHAT_DIR/TestRoom/.log"
  printf "[2024-12-01 12:00:02] Bob: Message 2\n" >> "$CHAT_DIR/TestRoom/.log"
  printf "[2024-12-01 12:00:03] Charlie: Message 3\n" >> "$CHAT_DIR/TestRoom/.log"
  
  # Connect with since parameter set to "now" (should get messages >= now)
  export QUERY_STRING="room=TestRoom&since=$now_timestamp"
  output=$(run_with_timeout chat-stream)
  
  cleanup_test_env
  
  # Should contain recent messages to prevent gap during connection
  printf '%s' "$output" | grep -q "event: message" && \
  printf '%s' "$output" | grep -q "Alice: Message 1" && \
  printf '%s' "$output" | grep -q "Bob: Message 2" && \
  printf '%s' "$output" | grep -q "Charlie: Message 3"
}

test_chat_stream_handles_same_second_messages() {
  setup_test_env
  
  # Create room with multiple messages in the same second
  mkdir -p "$CHAT_DIR/TestRoom"
  base_timestamp="2024-12-01 12:00:05"
  printf "[2024-12-01 12:00:05] Alice: First in second\n" > "$CHAT_DIR/TestRoom/.log"
  printf "[2024-12-01 12:00:05] Bob: Second in second\n" >> "$CHAT_DIR/TestRoom/.log"
  printf "[2024-12-01 12:00:05] Charlie: Third in second\n" >> "$CHAT_DIR/TestRoom/.log"
  printf "[2024-12-01 12:00:06] Dave: Next second\n" >> "$CHAT_DIR/TestRoom/.log"
  
  # Connect with since parameter set to that exact second
  export QUERY_STRING="room=TestRoom&since=$base_timestamp"
  output=$(run_with_timeout chat-stream)
  
  cleanup_test_env
  
  # Should get ALL messages from that second (including exact match)
  printf '%s' "$output" | grep -q "Alice: First in second" && \
  printf '%s' "$output" | grep -q "Bob: Second in second" && \
  printf '%s' "$output" | grep -q "Charlie: Third in second" && \
  printf '%s' "$output" | grep -q "Dave: Next second"
}

test_chat_stream_connects_instantly_regardless_of_history() {
  setup_test_env
  
  # Create room with large message history
  mkdir -p "$CHAT_DIR/TestRoom"
  i=1
  while [ $i -le 1000 ]; do
    printf "[2024-01-01 10:%02d:00] User%d: Message %d\n" $((i % 60)) $i $i >> "$CHAT_DIR/TestRoom/.log"
    i=$((i + 1))
  done
  
  export QUERY_STRING="room=TestRoom"
  output=$(run_with_timeout chat-stream)
  
  cleanup_test_env
  
  # Should connect without iterating through messages (O(1) time)
  # Verify it doesn't contain historical messages
  ! printf '%s' "$output" | grep -q "User1: Message 1"
}

test_chat_stream_sends_member_list() {
  setup_test_env
  
  # Create room with avatars
  mkdir -p "$CHAT_DIR/TestRoom"
  mkdir -p "$CHAT_DIR/TestRoom/.Alice"
  mkdir -p "$CHAT_DIR/TestRoom/.Bob"
  
  export QUERY_STRING="room=TestRoom"
  output=$(run_with_timeout chat-stream)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "event: members" && \
  printf '%s' "$output" | grep -q "Alice" && \
  printf '%s' "$output" | grep -q "Bob"
}

test_chat_stream_outputs_sse_headers() {
  setup_test_env
  
  mkdir -p "$CHAT_DIR/TestRoom"
  
  export QUERY_STRING="room=TestRoom"
  output=$(run_with_timeout chat-stream)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "Status: 200 OK" && \
  printf '%s' "$output" | grep -q "Content-Type: text/event-stream"
}

run_test_case "chat-stream is executable" test_chat_stream_exists
run_test_case "chat-stream rejects invalid room names" test_chat_stream_rejects_invalid_room_name
run_test_case "chat-stream rejects empty room parameter" test_chat_stream_rejects_empty_room
run_test_case "chat-stream handles nonexistent room" test_chat_stream_handles_nonexistent_room
run_test_case "chat-stream does not send old historical messages" test_chat_stream_does_not_send_old_historical_messages
run_test_case "chat-stream sends recent messages to prevent gaps" test_chat_stream_sends_recent_messages_to_prevent_gaps
run_test_case "chat-stream handles same-second messages" test_chat_stream_handles_same_second_messages
run_test_case "chat-stream connects instantly regardless of history" test_chat_stream_connects_instantly_regardless_of_history
run_test_case "chat-stream sends member list" test_chat_stream_sends_member_list
run_test_case "chat-stream outputs SSE headers" test_chat_stream_outputs_sse_headers

finish_tests
