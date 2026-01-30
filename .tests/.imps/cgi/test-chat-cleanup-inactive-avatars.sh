#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_chat_cleanup_inactive_avatars_exists() {
  [ -x "spells/.imps/cgi/chat-cleanup-inactive-avatars" ]
}

run_test_case "chat-cleanup-inactive-avatars is executable" test_chat_cleanup_inactive_avatars_exists
finish_tests
