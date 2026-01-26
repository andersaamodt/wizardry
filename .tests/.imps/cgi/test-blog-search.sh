#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_blog_search_exists() {
  [ -x "spells/.imps/cgi/blog-search" ]
}

run_test_case "blog-search is executable" test_blog_search_exists
finish_tests
