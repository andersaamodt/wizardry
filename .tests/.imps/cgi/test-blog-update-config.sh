#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_blog_update_config_exists() {
  [ -x "spells/.imps/cgi/blog-update-config" ]
}

test_blog_update_config_requires_auth() {
  export QUERY_STRING=""
  output=$(spells/.imps/cgi/blog-update-config 2>&1)
  printf '%s' "$output" | grep -q '"success":false'
}

run_test_case "blog-update-config is executable" test_blog_update_config_exists
run_test_case "blog-update-config requires authentication" test_blog_update_config_requires_auth
finish_tests
