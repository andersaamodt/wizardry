#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_blog_theme_css_serves_file() {
  skip-if-compiled || return $?

  test_web_root=$(temp-dir web-theme-test)
  export WIZARDRY_SITES_DIR="$test_web_root"
  export WIZARDRY_SITE_NAME="testsite"

  site_root=$(get-site-data-dir "..")
  site_config="$site_root/site.conf"
  site_dir="$test_web_root/testsite"
  mkdir -p "$(dirname "$site_config")" "$site_dir/site/static/themes"

  config-set "$site_config" theme "lich"

  theme_file="$site_dir/site/static/themes/lich.css"
  printf '/* lich theme test */\n' > "$theme_file"

  QUERY_STRING=""
  export QUERY_STRING
  run_spell spells/.imps/cgi/blog-theme.css
  assert_success
  assert_output_contains "text/css"
  assert_output_contains "lich theme test"

  rm -rf "$test_web_root"
}

run_test_case "blog-theme.css serves configured theme" test_blog_theme_css_serves_file

finish_tests
