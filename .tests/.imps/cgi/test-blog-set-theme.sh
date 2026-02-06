#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_blog_set_theme_persists() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-theme-test)
  export WIZARDRY_SITES_DIR="$test_web_root"
  export WIZARDRY_SITE_NAME="testsite"

  site_root=$(get-site-data-dir "..")
  site_config="$site_root/site.conf"

  QUERY_STRING="theme=lich"
  export QUERY_STRING
  run_spell spells/.imps/cgi/blog-set-theme
  assert_success
  assert_output_contains '"success":true'

  theme_value=$(config-get "$site_config" theme)
  [ "$theme_value" = "lich" ] || {
    TEST_FAILURE_REASON="expected theme=lich, got ${theme_value:-empty}"
    rm -rf "$test_web_root"
    return 1
  }

  rm -rf "$test_web_root"
}

run_test_case "blog-set-theme persists config" test_blog_set_theme_persists

finish_tests
