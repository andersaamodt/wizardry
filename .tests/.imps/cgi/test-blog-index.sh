#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_blog_index_exists() {
  [ -x "spells/.imps/cgi/blog-index" ]
}

run_test_case "blog-index is executable" test_blog_index_exists
finish_tests
