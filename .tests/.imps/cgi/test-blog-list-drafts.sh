#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_blog_list_drafts_exists() {
  [ -x "spells/.imps/cgi/blog-list-drafts" ]
}

test_blog_list_drafts_requires_auth() {
  export QUERY_STRING=""
  output=$(spells/.imps/cgi/blog-list-drafts 2>&1)
  printf '%s' "$output" | grep -q '"success":false'
}

run_test_case "blog-list-drafts is executable" test_blog_list_drafts_exists
run_test_case "blog-list-drafts requires authentication" test_blog_list_drafts_requires_auth
finish_tests
