#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_chat_stream_exists() {
  [ -x "spells/.imps/cgi/chat-stream" ]
}

run_test_case "chat-stream is executable" test_chat_stream_exists
finish_tests
