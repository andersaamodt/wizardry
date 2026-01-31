#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_returns_base_sitedata_dir() {
  WIZARDRY_SITE_NAME="testsite" WIZARDRY_SITES_DIR="/tmp/sites" \
    run_spell "spells/.imps/cgi/get-site-data-dir"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "/tmp/sites/.sitedata/testsite" ] || return 1
}

test_returns_subdir_path() {
  WIZARDRY_SITE_NAME="testsite" WIZARDRY_SITES_DIR="/tmp/sites" \
    run_spell "spells/.imps/cgi/get-site-data-dir" "uploads"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "/tmp/sites/.sitedata/testsite/uploads" ] || return 1
}

test_defaults_to_default_site() {
  WIZARDRY_SITES_DIR="/tmp/sites" \
    run_spell "spells/.imps/cgi/get-site-data-dir"
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "/tmp/sites/.sitedata/default" ] || return 1
}

test_defaults_to_home_sites_dir() {
  WIZARDRY_SITE_NAME="mysite" \
    run_spell "spells/.imps/cgi/get-site-data-dir"
  [ "$STATUS" -eq 0 ] || return 1
  # Should contain sites/.sitedata/mysite (actual HOME value varies)
  printf '%s' "$OUTPUT" | grep -q "sites/.sitedata/mysite" || return 1
}

run_test_case "returns base sitedata directory" test_returns_base_sitedata_dir
run_test_case "returns subdirectory path when provided" test_returns_subdir_path
run_test_case "defaults to 'default' site name" test_defaults_to_default_site
run_test_case "defaults to HOME/sites for sites directory" test_defaults_to_home_sites_dir
finish_tests
