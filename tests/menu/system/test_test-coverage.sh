#!/bin/sh
# Behavioral cases (derived from --help):
# - test-coverage reports matched and missing spells

set -eu

. "$(dirname "$0")/lib/test_common.sh"

test_coverage_reports_spell_matches() {
  root=$(make_tempdir)
  mkdir -p "$root/spells/nested" "$root/tests/nested"
  touch "$root/spells/cast" "$root/spells/nested/wand" "$root/spells/untested"

  cat <<'TEST' >"$root/tests/test_cast.sh"
#!/bin/sh
run_test_case one noop
run_test_case two noop
TEST

  cat <<'TEST' >"$root/tests/nested/test_wand.sh"
#!/bin/sh
run_test_case single noop
TEST

  NO_COLOR=1 run_spell "spells/menu/system/test-coverage" --root "$root"
  assert_success || return 1
  assert_output_contains "spells/cast" || return 1
  assert_output_contains "test_cast.sh (2 subtests)" || return 1
  assert_output_contains "spells/nested/wand" || return 1
  assert_output_contains "tests/nested/test_wand.sh (1 subtests)" || return 1
  assert_output_contains "spells/untested" || return 1
  assert_output_contains "none (0 subtests)" || return 1
  assert_output_contains "Coverage: 2/3 spells with tests" || return 1
}

run_test_case "test-coverage reports matched and missing spells" test_coverage_reports_spell_matches

finish_tests
