#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_chat_list_rooms_exists() {
  [ -x "spells/.imps/cgi/chat-list-rooms" ]
}

setup_list_rooms_env() {
  test_tmpdir=$(mktemp -d)
  export WIZARDRY_SITES_DIR="$test_tmpdir"
  export WIZARDRY_SITE_NAME="default"
  CHAT_DIR="$test_tmpdir/.sitedata/default/chatrooms"
  mkdir -p "$CHAT_DIR"
}

cleanup_list_rooms_env() {
  if [ -n "${test_tmpdir:-}" ] && [ -d "$test_tmpdir" ]; then
    rm -rf "$test_tmpdir"
  fi
  unset WIZARDRY_SITES_DIR
  unset WIZARDRY_SITE_NAME
}

test_chat_list_rooms_filters_names_and_escapes_messages() {
  setup_list_rooms_env
  mkdir -p "$CHAT_DIR/GoodRoom" "$CHAT_DIR/bad\"room"
  printf '%s\n' '[2026-04-29 12:00:00] user: <script>alert(1)</script>' \
    > "$CHAT_DIR/GoodRoom/.log"
  printf '%s\n' 'bad' > "$CHAT_DIR/bad\"room/.log"

  output=$(chat-list-rooms 2>&1)
  status=$?

  cleanup_list_rooms_env

  if [ $status -ne 0 ]; then
    TEST_FAILURE_REASON="Script failed with status $status"
    return 1
  fi
  if ! printf '%s' "$output" | grep -q 'data-room="GoodRoom"'; then
    TEST_FAILURE_REASON="Valid room missing from output: $output"
    return 1
  fi
  if printf '%s' "$output" | grep -F 'bad"room' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="Invalid room name leaked into room list: $output"
    return 1
  fi
  if printf '%s' "$output" | grep -F '<script>alert(1)</script>' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="Last message was not HTML-escaped: $output"
    return 1
  fi
  if ! printf '%s' "$output" | grep -F '&lt;script&gt;alert(1)&lt;/script&gt;' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="Escaped last message missing: $output"
    return 1
  fi
}

run_test_case "chat-list-rooms is executable" test_chat_list_rooms_exists
run_test_case "chat-list-rooms filters names and escapes messages" \
  test_chat_list_rooms_filters_names_and_escapes_messages
finish_tests
