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

test_blog_get_config_sanitizes_imported_config() {
  skip-if-compiled || return $?

  sites_dir=$(temp-dir blog-config-sites)
  mkdir -p "$sites_dir/.sitedata/testsite"
  cat > "$sites_dir/.sitedata/site.conf" <<'EOF'
registration_enabled=true,"forged":true
site_title=Bad "Title"
theme=bad-theme
EOF

  WIZARDRY_SITE_NAME=testsite WIZARDRY_SITES_DIR="$sites_dir" \
    run_cmd spells/.imps/cgi/blog-get-config
  assert_success || return 1

  if printf '%s' "$OUTPUT" | grep -F '"forged":true' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="blog-get-config emitted unvalidated boolean JSON"
    rm -rf "$sites_dir"
    return 1
  fi
  assert_output_contains '"registration_enabled":true' || return 1
  assert_output_contains '"site_title":"Bad \"Title\""' || return 1
  assert_output_contains '"theme":"archmage"' || return 1

  rm -rf "$sites_dir"
}

run_test_case "blog-get-config is executable" test_blog_get_config_exists
run_test_case "blog-get-config returns JSON" test_blog_get_config_returns_json
run_test_case "blog-get-config sanitizes imported config" \
  test_blog_get_config_sanitizes_imported_config
finish_tests
