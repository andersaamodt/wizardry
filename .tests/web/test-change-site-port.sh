#!/bin/sh
# Test change-site-port spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_change_site_port_help() {
  run_spell spells/web/change-site-port --help
  assert_success
  assert_output_contains "Usage:"
}

test_change_site_port_validates_sitename() {
  skip-if-compiled || return $?
  run_spell spells/web/change-site-port
  assert_status 2
  assert_error_contains "SITENAME required"
}

test_change_site_port_validates_port() {
  skip-if-compiled || return $?
  
  # Set up test environment
  test_web_root=$(temp-dir web-wizardry-test)
  export WEB_WIZARDRY_ROOT="$test_web_root"
  
  # Create a test site
  mkdir -p "$test_web_root/testsite"
  printf 'site-name=testsite\nport=8080\ndomain=localhost\nhttps=false\n' > "$test_web_root/testsite/site.conf"
  
  # Test invalid port (non-numeric)
  run_spell spells/web/change-site-port testsite abc
  assert_status 2
  assert_error_contains "port must be numeric"
  
  # Test invalid port (too low)
  run_spell spells/web/change-site-port testsite 0
  assert_status 2
  assert_error_contains "port must be between 1 and 65535"
  
  # Test invalid port (too high)
  run_spell spells/web/change-site-port testsite 70000
  assert_status 2
  assert_error_contains "port must be between 1 and 65535"
  
  # Cleanup
  rm -rf "$test_web_root"
}

test_change_site_port_rejects_path_shaped_site_name() {
  skip-if-compiled || return $?

  tmpdir=$(make_tempdir)
  web_root="$tmpdir/sites"
  escape_dir="$tmpdir/escape"
  mkdir -p "$web_root" "$escape_dir"
  printf 'site-name=escape\nport=8080\ndomain=localhost\nhttps=false\n' > "$escape_dir/site.conf"

  WEB_WIZARDRY_ROOT="$web_root" WIZARDRY_SITES_DIR="$web_root" \
    run_spell spells/web/change-site-port ../escape 9090

  assert_failure || return 1
  assert_error_contains "invalid site name" || return 1
  if ! grep -q '^port=8080$' "$escape_dir/site.conf"; then
    TEST_FAILURE_REASON="change-site-port modified config outside WEB_WIZARDRY_ROOT"
    return 1
  fi

  rm -rf "$tmpdir"
}

run_test_case "change-site-port --help" test_change_site_port_help
run_test_case "change-site-port validates sitename" test_change_site_port_validates_sitename
run_test_case "change-site-port validates port" test_change_site_port_validates_port
run_test_case "change-site-port rejects path-shaped site names" \
  test_change_site_port_rejects_path_shaped_site_name

finish_tests
