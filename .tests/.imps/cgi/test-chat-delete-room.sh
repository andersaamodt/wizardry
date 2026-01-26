#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_chat_delete_room_exists() {
  [ -x "spells/.imps/cgi/chat-delete-room" ]
}

run_test_case "chat-delete-room is executable" test_chat_delete_room_exists
finish_tests
