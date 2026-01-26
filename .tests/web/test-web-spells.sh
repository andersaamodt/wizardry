#!/bin/sh
# Basic smoke tests for web spells

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_configure_nginx_help() {
  run_spell spells/web/configure-nginx --help
  assert_success
  assert_output_contains "Usage:"
}

test_https_help() {
  run_spell spells/web/https --help
  assert_success
  assert_output_contains "Usage:"
}

test_serve_site_help() {
  run_spell spells/web/serve-site --help
  assert_success
  assert_output_contains "Usage:"
}

test_stop_site_help() {
  run_spell spells/web/stop-site --help
  assert_success
  assert_output_contains "Usage:"
}

test_delete_site_help() {
  run_spell spells/web/delete-site --help
  assert_success
  assert_output_contains "Usage:"
}

run_test_case "configure-nginx --help" test_configure_nginx_help
run_test_case "https --help" test_https_help
run_test_case "serve-site --help" test_serve_site_help
run_test_case "stop-site --help" test_stop_site_help
run_test_case "delete-site --help" test_delete_site_help

finish_tests
