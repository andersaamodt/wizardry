#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_detect_environment_runs() {
  output=$(_run_spell "spells/.imps/test/detect-test-environment")
  _assert_success
}

test_detect_environment_has_facts_markers() {
  output=$(_run_spell "spells/.imps/test/detect-test-environment")
  _assert_output_contains "=== Test Environment Facts ==="
  _assert_output_contains "=== End Environment Facts ==="
}

test_detect_environment_reports_platform() {
  output=$(_run_spell "spells/.imps/test/detect-test-environment")
  _assert_output_contains "Platform:"
}

test_detect_environment_reports_ci_status() {
  output=$(_run_spell "spells/.imps/test/detect-test-environment")
  _assert_output_contains "CI:"
}

test_detect_environment_reports_xattr_tools() {
  output=$(_run_spell "spells/.imps/test/detect-test-environment")
  _assert_output_contains "xattr:"
}

test_detect_environment_reports_coreutils() {
  output=$(_run_spell "spells/.imps/test/detect-test-environment")
  _assert_output_contains "coreutils:"
}

test_detect_environment_reports_filesystem() {
  output=$(_run_spell "spells/.imps/test/detect-test-environment")
  _assert_output_contains "filesystem:"
}

test_detect_environment_reports_environment() {
  output=$(_run_spell "spells/.imps/test/detect-test-environment")
  _assert_output_contains "environment:"
}

_run_test_case "detect-test-environment runs successfully" test_detect_environment_runs
_run_test_case "detect-test-environment has facts markers" test_detect_environment_has_facts_markers
_run_test_case "detect-test-environment reports platform" test_detect_environment_reports_platform
_run_test_case "detect-test-environment reports CI status" test_detect_environment_reports_ci_status
_run_test_case "detect-test-environment reports xattr tools" test_detect_environment_reports_xattr_tools
_run_test_case "detect-test-environment reports coreutils" test_detect_environment_reports_coreutils
_run_test_case "detect-test-environment reports filesystem" test_detect_environment_reports_filesystem
_run_test_case "detect-test-environment reports environment" test_detect_environment_reports_environment

_finish_tests
