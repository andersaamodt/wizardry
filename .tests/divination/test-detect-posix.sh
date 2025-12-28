#!/bin/sh
# Behavioral cases (derived from --help):
# - detect-posix shows usage with --help
# - detect-posix succeeds for minimal probe sets
# - detect-posix reports missing tools

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

detect_posix_shows_usage() {
  run_spell "spells/divination/detect-posix" --help
  assert_success || return 1
  assert_output_contains "Usage: detect-posix" || return 1
}

detect_posix_reports_success_for_minimal_probe() {
  DETECT_POSIX_TOOLS="sh" DETECT_POSIX_PROBES="sh" run_spell "spells/divination/detect-posix"
  assert_success || return 1
  assert_output_contains "POSIX toolchain and probes look healthy." || return 1
}

detect_posix_reports_missing_tools() {
  DETECT_POSIX_TOOLS="nope" DETECT_POSIX_PROBES="sh" run_spell "spells/divination/detect-posix"
  assert_failure || return 1
  assert_error_contains "detect-posix: missing tools: nope" || return 1
}

detect_posix_awk_probe_works() {
  # Test that the awk probe doesn't fail with "unbound variable" error
  # This tests the fix for the \\$1 -> \$1 escaping issue
  DETECT_POSIX_TOOLS="awk" DETECT_POSIX_PROBES="awk" run_spell "spells/divination/detect-posix"
  assert_success || return 1
  assert_output_contains "POSIX toolchain and probes look healthy." || return 1
}

run_test_case "detect-posix shows usage with --help" detect_posix_shows_usage
run_test_case "detect-posix succeeds for minimal probe" detect_posix_reports_success_for_minimal_probe
run_test_case "detect-posix reports missing tools" detect_posix_reports_missing_tools
run_test_case "detect-posix awk probe works without unbound variable error" detect_posix_awk_probe_works


# Test via source-then-invoke pattern  
