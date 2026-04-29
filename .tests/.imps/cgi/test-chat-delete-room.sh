#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_chat_delete_room_exists() {
  [ -x "spells/.imps/cgi/chat-delete-room" ]
}

test_chat_delete_room_rejects_path_room() {
  skip-if-compiled || return $?

  sites_dir=$(temp-dir chat-delete-room-sites)
  mkdir -p "$sites_dir/.sitedata/testsite/chatrooms" "$sites_dir/.sitedata/testsite/escape"
  printf '%s\n' keep > "$sites_dir/.sitedata/testsite/escape/keep"

  QUERY_STRING='room=..%2Fescape' \
    WIZARDRY_SITE_NAME=testsite WIZARDRY_SITES_DIR="$sites_dir" \
    run_cmd spells/.imps/cgi/chat-delete-room
  assert_success || return 1
  assert_output_contains "Invalid room name" || return 1

  if [ ! -f "$sites_dir/.sitedata/testsite/escape/keep" ]; then
    TEST_FAILURE_REASON="chat-delete-room deleted outside chatrooms for path-shaped room"
    rm -rf "$sites_dir"
    return 1
  fi

  rm -rf "$sites_dir"
}

run_test_case "chat-delete-room is executable" test_chat_delete_room_exists
run_test_case "chat-delete-room rejects path-shaped room" \
  test_chat_delete_room_rejects_path_room
finish_tests
