#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_detect_environment_runs() {
  run_spell "spells/.imps/test/detect-test-environment"
  assert_success
}

test_detect_environment_has_facts_markers() {
  run_spell "spells/.imps/test/detect-test-environment"
  assert_output_contains "=== Test Environment Facts ==="
  assert_output_contains "=== End Environment Facts ==="
}

test_detect_environment_reports_platform() {
  run_spell "spells/.imps/test/detect-test-environment"
  assert_output_contains "Platform:"
}

test_detect_environment_reports_ci_status() {
  run_spell "spells/.imps/test/detect-test-environment"
  assert_output_contains "CI:"
}

test_detect_environment_reports_xattr_tools() {
  run_spell "spells/.imps/test/detect-test-environment"
  assert_output_contains "xattr:"
}

test_detect_environment_reports_coreutils() {
  run_spell "spells/.imps/test/detect-test-environment"
  assert_output_contains "coreutils:"
}

test_detect_environment_reports_filesystem() {
  run_spell "spells/.imps/test/detect-test-environment"
  assert_output_contains "filesystem:"
}

test_detect_environment_reports_environment() {
  run_spell "spells/.imps/test/detect-test-environment"
  assert_output_contains "environment:"
}

run_test_case "detect-test-environment runs successfully" test_detect_environment_runs
run_test_case "detect-test-environment has facts markers" test_detect_environment_has_facts_markers
run_test_case "detect-test-environment reports platform" test_detect_environment_reports_platform
run_test_case "detect-test-environment reports CI status" test_detect_environment_reports_ci_status
run_test_case "detect-test-environment reports xattr tools" test_detect_environment_reports_xattr_tools
run_test_case "detect-test-environment reports coreutils" test_detect_environment_reports_coreutils
run_test_case "detect-test-environment reports filesystem" test_detect_environment_reports_filesystem
run_test_case "detect-test-environment reports environment" test_detect_environment_reports_environment

finish_tests
