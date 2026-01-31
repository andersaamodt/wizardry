#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Setup test environment
setup_test_env() {
  test_tmpdir=$(mktemp -d)
  export WIZARDRY_SITES_DIR="$test_tmpdir"
  export WIZARDRY_SITE_NAME="default"
  CHAT_DIR="$test_tmpdir/.sitedata/default/chatrooms"
  export CHAT_DIR
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
  output=$(timeout 1 chat-stream 2>&1 || true)
  
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
  output=$(timeout 1 chat-stream 2>&1 || true)
  
  cleanup_test_env
  
  # Should not error, should use General room
  ! printf '%s' "$output" | grep -q "event: error"
}

test_chat_stream_handles_nonexistent_room() {
  setup_test_env
  
  export QUERY_STRING="room=NonExistentRoom"
  output=$(timeout 1 chat-stream 2>&1 || true)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "event: error" && \
  printf '%s' "$output" | grep -q "Room not found"
}

test_chat_stream_sends_empty_event_for_no_messages() {
  setup_test_env
  
  # Create empty room
  mkdir -p "$CHAT_DIR/TestRoom"
  
  export QUERY_STRING="room=TestRoom"
  output=$(timeout 1 chat-stream 2>&1 || true)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "event: empty" && \
  printf '%s' "$output" | grep -q "No messages yet"
}

test_chat_stream_sends_initial_messages() {
  setup_test_env
  
  # Create room with messages
  mkdir -p "$CHAT_DIR/TestRoom"
  printf "[2024-01-01 10:00:00] Alice: Hello\n" > "$CHAT_DIR/TestRoom/.log"
  printf "[2024-01-01 10:01:00] Bob: Hi there\n" >> "$CHAT_DIR/TestRoom/.log"
  
  export QUERY_STRING="room=TestRoom"
  output=$(timeout 1 chat-stream 2>&1 || true)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "event: message" && \
  printf '%s' "$output" | grep -q "Alice: Hello" && \
  printf '%s' "$output" | grep -q "Bob: Hi there"
}

test_chat_stream_sends_member_list() {
  setup_test_env
  
  # Create room with avatars
  mkdir -p "$CHAT_DIR/TestRoom"
  mkdir -p "$CHAT_DIR/TestRoom/.Alice"
  mkdir -p "$CHAT_DIR/TestRoom/.Bob"
  
  export QUERY_STRING="room=TestRoom"
  output=$(timeout 1 chat-stream 2>&1 || true)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "event: members" && \
  printf '%s' "$output" | grep -q "Alice" && \
  printf '%s' "$output" | grep -q "Bob"
}

test_chat_stream_outputs_sse_headers() {
  setup_test_env
  
  mkdir -p "$CHAT_DIR/TestRoom"
  
  export QUERY_STRING="room=TestRoom"
  output=$(timeout 1 chat-stream 2>&1 || true)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "Status: 200 OK" && \
  printf '%s' "$output" | grep -q "Content-Type: text/event-stream"
}

run_test_case "chat-stream is executable" test_chat_stream_exists
run_test_case "chat-stream rejects invalid room names" test_chat_stream_rejects_invalid_room_name
run_test_case "chat-stream rejects empty room parameter" test_chat_stream_rejects_empty_room
run_test_case "chat-stream handles nonexistent room" test_chat_stream_handles_nonexistent_room
run_test_case "chat-stream sends empty event for no messages" test_chat_stream_sends_empty_event_for_no_messages
run_test_case "chat-stream sends initial messages" test_chat_stream_sends_initial_messages
run_test_case "chat-stream sends member list" test_chat_stream_sends_member_list
run_test_case "chat-stream outputs SSE headers" test_chat_stream_outputs_sse_headers

finish_tests
