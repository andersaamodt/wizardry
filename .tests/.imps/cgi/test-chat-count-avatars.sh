#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_chat_count_avatars_exists() {
  [ -x "spells/.imps/cgi/chat-count-avatars" ]
}

setup_count_env() {
  test_tmpdir=$(mktemp -d)
  export WIZARDRY_SITES_DIR="$test_tmpdir/sites"
  export WIZARDRY_SITE_NAME=""
  CHAT_DIR="$WIZARDRY_SITES_DIR/.sitedata/default/chatrooms"
}

cleanup_count_env() {
  if [ -n "${test_tmpdir:-}" ] && [ -d "$test_tmpdir" ]; then
    rm -rf "$test_tmpdir"
  fi
  unset WIZARDRY_SITES_DIR
  unset WIZARDRY_SITE_NAME
}

test_chat_count_avatars_rejects_path_room() {
  setup_count_env
  mkdir -p "$WIZARDRY_SITES_DIR/.sitedata/default/.escaped"

  export QUERY_STRING="room=.."
  output=$(chat-count-avatars 2>&1)
  status=$?

  cleanup_count_env

  if [ $status -ne 0 ]; then
    TEST_FAILURE_REASON="Script failed with status $status"
    return 1
  fi

  json=$(printf '%s' "$output" | sed -n '/^{/,$p')
  if ! printf '%s' "$json" | grep -q '{"error": "Invalid room name"}'; then
    TEST_FAILURE_REASON="Expected invalid room error, got: $json"
    return 1
  fi
}

test_chat_count_avatars_skips_invalid_avatar_names() {
  setup_count_env
  room_name="test-invalid-avatar"
  room_dir="$CHAT_DIR/$room_name"
  mkdir -p "$room_dir/.gooduser" "$room_dir/.bad\"user"
  touch "$room_dir/.log"

  export QUERY_STRING="room=$room_name"
  output=$(chat-count-avatars 2>&1)
  status=$?

  cleanup_count_env

  if [ $status -ne 0 ]; then
    TEST_FAILURE_REASON="Script failed with status $status"
    return 1
  fi

  json=$(printf '%s' "$output" | sed -n '/^{/,$p')
  if ! printf '%s' "$json" | grep -q '{"count": 1}'; then
    TEST_FAILURE_REASON="Expected one valid avatar, got: $json"
    return 1
  fi
}

run_test_case "chat-count-avatars is executable" test_chat_count_avatars_exists
run_test_case "chat-count-avatars rejects path-shaped room" test_chat_count_avatars_rejects_path_room
run_test_case "chat-count-avatars skips invalid avatar names" test_chat_count_avatars_skips_invalid_avatar_names
finish_tests
