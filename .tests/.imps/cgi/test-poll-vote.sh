#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_poll_vote_exists() {
  [ -x "spells/.imps/cgi/poll-vote" ]
}

run_test_case "poll-vote is executable" test_poll_vote_exists
finish_tests
