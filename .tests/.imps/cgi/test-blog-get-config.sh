#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_blog_get_config_exists() {
  [ -x "spells/.imps/cgi/blog-get-config" ]
}

test_blog_get_config_returns_json() {
  output=$(spells/.imps/cgi/blog-get-config 2>&1)
  printf '%s' "$output" | grep -q '"success":true'
}

run_test_case "blog-get-config is executable" test_blog_get_config_exists
run_test_case "blog-get-config returns JSON" test_blog_get_config_returns_json
finish_tests
