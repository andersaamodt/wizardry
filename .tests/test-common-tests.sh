#!/bin/sh

# Test common-tests.sh functionality

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_runs_without_arguments() {
  # Should run on all spells when no arguments provided
  # This is a long test, so just verify it exits successfully
  sh "$ROOT_DIR/.tests/common-tests.sh" > "$WIZARDRY_TMPDIR/common-test-output.txt" 2>&1
  exit_code=$?
  
  if [ "$exit_code" -ne 0 ]; then
    return 1
  fi
  
  # Check that tests passed message appears
  if ! grep -q "tests passed" "$WIZARDRY_TMPDIR/common-test-output.txt"; then
    return 1
  fi
  
  return 0
}

test_accepts_single_spell_path() {
  # Should accept a single spell path and run tests on just that spell
  sh "$ROOT_DIR/.tests/common-tests.sh" "spells/cantrips/ask-yn" \
    > "$WIZARDRY_TMPDIR/common-test-single.txt" 2>&1
  exit_code=$?
  
  if [ "$exit_code" -ne 0 ]; then
    return 1
  fi
  
  # Should run tests and show results
  if ! grep -q "tests passed" "$WIZARDRY_TMPDIR/common-test-single.txt"; then
    return 1
  fi
  
  return 0
}

test_accepts_multiple_spell_paths() {
  # Should accept multiple spell paths
  sh "$ROOT_DIR/.tests/common-tests.sh" \
    "spells/cantrips/ask-yn" \
    "spells/cantrips/ask-text" \
    > "$WIZARDRY_TMPDIR/common-test-multi.txt" 2>&1
  exit_code=$?
  
  if [ "$exit_code" -ne 0 ]; then
    return 1
  fi
  
  # Should run tests and show results
  if ! grep -q "tests passed" "$WIZARDRY_TMPDIR/common-test-multi.txt"; then
    return 1
  fi
  
  return 0
}

test_handles_relative_spell_paths() {
  # Should handle paths with spells/ prefix removed
  sh "$ROOT_DIR/.tests/common-tests.sh" "cantrips/ask-yn" \
    > "$WIZARDRY_TMPDIR/common-test-rel.txt" 2>&1
  exit_code=$?
  
  if [ "$exit_code" -ne 0 ]; then
    return 1
  fi
  
  # Should run tests and show results
  if ! grep -q "tests passed" "$WIZARDRY_TMPDIR/common-test-rel.txt"; then
    return 1
  fi
  
  return 0
}

_run_test_case "common-tests runs without arguments" test_runs_without_arguments
_run_test_case "common-tests accepts single spell path" test_accepts_single_spell_path
_run_test_case "common-tests accepts multiple spell paths" test_accepts_multiple_spell_paths
_run_test_case "common-tests handles relative paths" test_handles_relative_spell_paths

_finish_tests
