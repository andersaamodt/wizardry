#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_chat_list_avatars_exists() {
  [ -x "spells/.imps/cgi/chat-list-avatars" ]
}

run_test_case "chat-list-avatars is executable" test_chat_list_avatars_exists
finish_tests
