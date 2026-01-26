#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_chat_create_room_exists() {
  [ -x "spells/.imps/cgi/chat-create-room" ]
}

run_test_case "chat-create-room is executable" test_chat_create_room_exists
finish_tests
