#!/bin/sh
# Test suite for profile-tests spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/menu/system/profile-tests" --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
  _assert_output_contains "profile-tests" || return 1
}

test_profiles_single_test() {
  # Profile a single fast test
  _run_spell "spells/menu/system/profile-tests" --only ".imps/cond/test-has.sh"
  _assert_success || return 1
  _assert_output_contains "Test Suite Performance Profile" || return 1
  _assert_output_contains "Total tests:" || return 1
  _assert_output_contains "test-has.sh" || return 1
}

test_output_to_file() {
  tmpdir=$(_make_tempdir)
  output_file="$tmpdir/profile.txt"
  
  # Profile to file
  _run_spell "spells/menu/system/profile-tests" --only ".imps/cond/test-has.sh" --output "$output_file"
  _assert_success || return 1
  _assert_path_exists "$output_file" || return 1
  _assert_file_contains "$output_file" "Test Suite Performance Profile"
}

test_shows_time_distribution() {
  _run_spell "spells/menu/system/profile-tests" --only ".imps/cond/test-*.sh"
  _assert_success || return 1
  _assert_output_contains "Time Distribution:" || return 1
  _assert_output_contains "< 0.1s:" || return 1
}

test_shows_slowest_tests() {
  _run_spell "spells/menu/system/profile-tests" --only ".imps/cond/test-*.sh"
  _assert_success || return 1
  _assert_output_contains "Slowest Tests:" || return 1
  _assert_output_contains "TIME(s)" || return 1
  _assert_output_contains "STATUS" || return 1
}

test_handles_no_pattern_match() {
  _run_spell "spells/menu/system/profile-tests" --only "nonexistent/*.sh"
  _assert_failure || return 1
  _assert_error_contains "no tests found" || return 1
}

_run_test_case "profile-tests prints usage" test_help
_run_test_case "profile-tests profiles single test" test_profiles_single_test
_run_test_case "profile-tests writes output to file" test_output_to_file
_run_test_case "profile-tests shows time distribution" test_shows_time_distribution
_run_test_case "profile-tests shows slowest tests" test_shows_slowest_tests
_run_test_case "profile-tests handles no pattern match" test_handles_no_pattern_match

_finish_tests
