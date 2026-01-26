#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_chat_get_messages_exists() {
  [ -x "spells/.imps/cgi/chat-get-messages" ]
}

run_test_case "chat-get-messages is executable" test_chat_get_messages_exists
finish_tests
