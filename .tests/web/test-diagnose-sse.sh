#!/bin/sh
# Test diagnose-sse spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_diagnose_sse_help() {
  run_spell spells/web/diagnose-sse --help
  assert_success
  assert_output_contains "Usage:"
  assert_output_contains "diagnose-sse"
}

test_diagnose_sse_runs_without_error() {
  # diagnose-sse should run even if files don't exist
  # It will report what's missing but shouldn't fail
  run_spell spells/web/diagnose-sse
  assert_success
  assert_output_contains "SSE Deployment Diagnostic"
}

test_diagnose_sse_checks_repository_version() {
  # Test that it checks for repository version
  run_spell spells/web/diagnose-sse
  assert_success
  # Should check for repository chat-stream
  assert_output_contains "Repository"
}

test_diagnose_sse_checks_installed_version() {
  # Test that it checks for installed version
  run_spell spells/web/diagnose-sse
  assert_success
  # Should check for installed version
  assert_output_contains "Installed"
}

test_diagnose_sse_checks_unbuffering_tools() {
  # Test that it checks for unbuffering tools
  run_spell spells/web/diagnose-sse
  assert_success
  assert_output_contains "Unbuffering Tools"
}

test_diagnose_sse_checks_nginx_config() {
  # Test that it checks nginx configuration
  run_spell spells/web/diagnose-sse
  assert_success
  assert_output_contains "Nginx Configuration"
}

test_diagnose_sse_shows_next_steps() {
  # Test that it shows next steps
  run_spell spells/web/diagnose-sse
  assert_success
  assert_output_contains "Next Steps"
}

run_test_case "diagnose-sse --help works" test_diagnose_sse_help
run_test_case "diagnose-sse runs without error" test_diagnose_sse_runs_without_error
run_test_case "diagnose-sse checks repository version" test_diagnose_sse_checks_repository_version
run_test_case "diagnose-sse checks installed version" test_diagnose_sse_checks_installed_version
run_test_case "diagnose-sse checks unbuffering tools" test_diagnose_sse_checks_unbuffering_tools
run_test_case "diagnose-sse checks nginx config" test_diagnose_sse_checks_nginx_config
run_test_case "diagnose-sse shows next steps" test_diagnose_sse_shows_next_steps

finish_tests
