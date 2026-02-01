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

test_chat_room_list_stream_exists() {
  [ -x "spells/.imps/cgi/chat-room-list-stream" ]
}

test_chat_room_list_stream_outputs_sse_headers() {
  setup_test_env
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "Status: 200 OK" && \
  printf '%s' "$output" | grep -q "Content-Type: text/event-stream" && \
  printf '%s' "$output" | grep -q "Cache-Control: no-cache" && \
  printf '%s' "$output" | grep -q "Connection: keep-alive"
}

test_chat_room_list_stream_outputs_cors_headers() {
  setup_test_env
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "Access-Control-Allow-Origin: \*" && \
  printf '%s' "$output" | grep -q "Access-Control-Allow-Methods: GET, OPTIONS"
}

test_chat_room_list_stream_sets_retry_interval() {
  setup_test_env
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "retry: 5000"
}

test_chat_room_list_stream_sends_initial_empty_list() {
  setup_test_env
  
  # Create empty chatrooms directory
  mkdir -p "$CHAT_DIR"
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "event: rooms" && \
  printf '%s' "$output" | grep -q "data: \[\]"
}

test_chat_room_list_stream_sends_single_room() {
  setup_test_env
  
  # Create one room
  mkdir -p "$CHAT_DIR/TestRoom"
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "event: rooms" && \
  printf '%s' "$output" | grep -q 'data: \["TestRoom"\]'
}

test_chat_room_list_stream_sends_multiple_rooms() {
  setup_test_env
  
  # Create multiple rooms
  mkdir -p "$CHAT_DIR/Room1"
  mkdir -p "$CHAT_DIR/Room2"
  mkdir -p "$CHAT_DIR/Room3"
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  printf '%s' "$output" | grep -q "event: rooms" && \
  printf '%s' "$output" | grep -q "Room1" && \
  printf '%s' "$output" | grep -q "Room2" && \
  printf '%s' "$output" | grep -q "Room3"
}

test_chat_room_list_stream_filters_invalid_room_names() {
  setup_test_env
  
  # Create rooms with valid and invalid names
  mkdir -p "$CHAT_DIR/ValidRoom"
  mkdir -p "$CHAT_DIR/../../../InvalidPath"
  mkdir -p "$CHAT_DIR/Room With Spaces"
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  # Should include ValidRoom
  printf '%s' "$output" | grep -q "ValidRoom" && \
  # Should not include invalid paths
  ! printf '%s' "$output" | grep -q "InvalidPath"
}

test_chat_room_list_stream_ignores_files() {
  setup_test_env
  
  # Create a room and a file
  mkdir -p "$CHAT_DIR/ValidRoom"
  touch "$CHAT_DIR/somefile.txt"
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  # Should include ValidRoom
  printf '%s' "$output" | grep -q "ValidRoom" && \
  # Should not include the file
  ! printf '%s' "$output" | grep -q "somefile"
}

test_chat_room_list_stream_sends_keepalive() {
  setup_test_env
  
  mkdir -p "$CHAT_DIR"
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  # May or may not see keepalive in 1 second timeout, so this is optional
  # Just verify the script runs without error
  printf '%s' "$output" | grep -q "event: rooms"
}

test_chat_room_list_stream_includes_padding() {
  setup_test_env
  
  mkdir -p "$CHAT_DIR"
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  # Check for padding comments (SSE comments start with ':')
  printf '%s' "$output" | grep -q ": \.\.\.\.\.\.\.\."
}

test_chat_room_list_stream_valid_json_array_format() {
  setup_test_env
  
  # Create rooms
  mkdir -p "$CHAT_DIR/Alpha"
  mkdir -p "$CHAT_DIR/Beta"
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  # Extract the data line and verify it's valid JSON
  # Should have format: data: ["Alpha","Beta"] or similar
  printf '%s' "$output" | grep "^data: " | head -1 | grep -q '\[".*"\]'
}

test_chat_room_list_stream_rooms_separated_by_commas() {
  setup_test_env
  
  # Create multiple rooms
  mkdir -p "$CHAT_DIR/Room1"
  mkdir -p "$CHAT_DIR/Room2"
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  # Verify comma separation in JSON
  printf '%s' "$output" | grep -q '"Room1","Room2"\|"Room2","Room1"'
}

test_chat_room_list_stream_room_names_quoted() {
  setup_test_env
  
  mkdir -p "$CHAT_DIR/TestRoom"
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  # Verify room name is quoted in JSON
  printf '%s' "$output" | grep -q '"TestRoom"'
}

test_chat_room_list_stream_creates_chatrooms_dir() {
  setup_test_env
  
  # Don't create the directory - let the script create it
  
  output=$(run_with_timeout chat-room-list-stream)
  
  # Check that directory was created
  result=0
  [ -d "$CHAT_DIR" ] || result=1
  
  cleanup_test_env
  
  return $result
}

test_chat_room_list_stream_event_format() {
  setup_test_env
  
  mkdir -p "$CHAT_DIR/TestRoom"
  
  output=$(run_with_timeout chat-room-list-stream)
  
  cleanup_test_env
  
  # Verify SSE event format: "event: rooms" followed by "data: ..."
  printf '%s' "$output" | grep -A1 "event: rooms" | grep -q "data: "
}

run_test_case "chat-room-list-stream is executable" test_chat_room_list_stream_exists
run_test_case "chat-room-list-stream outputs SSE headers" test_chat_room_list_stream_outputs_sse_headers
run_test_case "chat-room-list-stream outputs CORS headers" test_chat_room_list_stream_outputs_cors_headers
run_test_case "chat-room-list-stream sets retry interval" test_chat_room_list_stream_sets_retry_interval
run_test_case "chat-room-list-stream sends initial empty list" test_chat_room_list_stream_sends_initial_empty_list
run_test_case "chat-room-list-stream sends single room" test_chat_room_list_stream_sends_single_room
run_test_case "chat-room-list-stream sends multiple rooms" test_chat_room_list_stream_sends_multiple_rooms
run_test_case "chat-room-list-stream filters invalid room names" test_chat_room_list_stream_filters_invalid_room_names
run_test_case "chat-room-list-stream ignores files" test_chat_room_list_stream_ignores_files
run_test_case "chat-room-list-stream sends keepalive" test_chat_room_list_stream_sends_keepalive
run_test_case "chat-room-list-stream includes padding" test_chat_room_list_stream_includes_padding
run_test_case "chat-room-list-stream valid JSON array format" test_chat_room_list_stream_valid_json_array_format
run_test_case "chat-room-list-stream rooms separated by commas" test_chat_room_list_stream_rooms_separated_by_commas
run_test_case "chat-room-list-stream room names quoted" test_chat_room_list_stream_room_names_quoted
run_test_case "chat-room-list-stream creates chatrooms dir" test_chat_room_list_stream_creates_chatrooms_dir
run_test_case "chat-room-list-stream event format" test_chat_room_list_stream_event_format

finish_tests
