#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_chat_delete_avatar_exists() {
  [ -x "spells/.imps/cgi/chat-delete-avatar" ]
}

test_chat_delete_avatar_rejects_path_username() {
  skip-if-compiled || return $?

  sites_dir=$(temp-dir chat-delete-avatar-sites)
  room_dir="$sites_dir/.sitedata/testsite/chatrooms/TestRoom"
  mkdir -p "$room_dir" "$sites_dir/.sitedata/testsite/escape"
  printf '%s\n' keep > "$sites_dir/.sitedata/testsite/escape/keep"

  QUERY_STRING='room=TestRoom&user=..%2F..%2Fescape' \
    WIZARDRY_SITE_NAME=testsite WIZARDRY_SITES_DIR="$sites_dir" \
    run_cmd spells/.imps/cgi/chat-delete-avatar
  assert_success || return 1
  assert_output_contains "Invalid username" || return 1

  if [ ! -f "$sites_dir/.sitedata/testsite/escape/keep" ]; then
    TEST_FAILURE_REASON="chat-delete-avatar deleted outside room for path-shaped username"
    rm -rf "$sites_dir"
    return 1
  fi

  rm -rf "$sites_dir"
}

run_test_case "chat-delete-avatar is executable" test_chat_delete_avatar_exists
run_test_case "chat-delete-avatar rejects path-shaped username" \
  test_chat_delete_avatar_rejects_path_username
finish_tests
