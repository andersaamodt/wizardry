#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_word_count_exists() {
  [ -x "spells/.imps/cgi/word-count" ]
}

run_test_case "word-count is executable" test_word_count_exists
finish_tests
