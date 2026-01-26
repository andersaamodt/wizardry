#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_blog_tags_exists() {
  [ -x "spells/.imps/cgi/blog-tags" ]
}

run_test_case "blog-tags is executable" test_blog_tags_exists
finish_tests
