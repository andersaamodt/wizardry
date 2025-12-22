#!/bin/sh
# Tests for the testing system itself - validates meta-requirements
# These tests ensure the testing infrastructure is properly architected
#
# NOTE: This is a meta-test (tests the test system itself).
# It intentionally has no corresponding spell - the "spell" being tested
# is the entire testing infrastructure (test-bootstrap, test-magic, boot imps, etc.)

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# REQ-ENV-001: Baseline PATH must be established before any commands
test_bootstrap_sets_baseline_path() {
  # Verify test-bootstrap content has PATH setup before set -eu
  bootstrap_file="$ROOT_DIR/spells/.imps/test/test-bootstrap"
  
  # Find line number of "set -eu"
  set_eu_line=$(grep -n "^set -eu" "$bootstrap_file" | head -1 | cut -d: -f1)
  
  # Find line number of PATH setup
  path_line=$(grep -n "baseline_path=" "$bootstrap_file" | head -1 | cut -d: -f1)
  
  # PATH setup must come before set -eu
  if [ -z "$set_eu_line" ] || [ -z "$path_line" ]; then
    TEST_FAILURE_REASON="Could not find set -eu or PATH setup in test-bootstrap"
    return 1
  fi
  
  if [ "$path_line" -ge "$set_eu_line" ]; then
    TEST_FAILURE_REASON="PATH setup (line $path_line) must come before set -eu (line $set_eu_line)"
    return 1
  fi
  
  return 0
}

# REQ-SAND-005: Sandbox unavailability must not fail tests
test_sandbox_fallback_is_graceful() {
  # Verify BWRAP_AVAILABLE flag exists and fallback logic is present
  if [ -z "${BWRAP_AVAILABLE-}" ]; then
    TEST_FAILURE_REASON="BWRAP_AVAILABLE flag not set by test-bootstrap"
    return 1
  fi
  
  # If bwrap is not available, verify we have a reason
  if [ "$BWRAP_AVAILABLE" -eq 0 ]; then
    if [ -z "${BWRAP_REASON-}" ]; then
      TEST_FAILURE_REASON="BWRAP_AVAILABLE=0 but no BWRAP_REASON set"
      return 1
    fi
  fi
  
  return 0
}

# REQ-STUB-003: Stub imps must match both prefixed and unprefixed names
test_stub_imps_have_correct_self_execute_patterns() {
  missing_patterns=""
  
  for stub_name in fathom-cursor fathom-terminal move-cursor cursor-blink stty await-keypress; do
    stub_file="$ROOT_DIR/spells/.imps/test/stub-$stub_name"
    
    if [ ! -f "$stub_file" ]; then
      missing_patterns="${missing_patterns:+$missing_patterns, }$stub_name(missing)"
      continue
    fi
    
    # Check for self-execute case statement
    if ! grep -qE 'case.*\$0.*in' "$stub_file"; then
      missing_patterns="${missing_patterns:+$missing_patterns, }$stub_name(no case)"
      continue
    fi
    
    # For stubs, unprefixed name is the stub name without "stub-" prefix
    unprefixed=$(printf '%s' "$stub_name" | sed 's/^stub-//')
    
    # Check both patterns exist
    has_stub_pattern=0
    has_unprefixed_pattern=0
    
    if grep -qE "\*/stub-$stub_name\)" "$stub_file" || grep -qE "\*/stub-$stub_name\|" "$stub_file"; then
      has_stub_pattern=1
    fi
    
    if grep -qE "\*/$unprefixed\)" "$stub_file" || grep -qE "\*/$unprefixed\|" "$stub_file"; then
      has_unprefixed_pattern=1
    fi
    
    if [ "$has_stub_pattern" -eq 0 ]; then
      missing_patterns="${missing_patterns:+$missing_patterns, }$stub_name(missing */stub-$stub_name)"
    fi
    if [ "$has_unprefixed_pattern" -eq 0 ]; then
      missing_patterns="${missing_patterns:+$missing_patterns, }$stub_name(missing */$unprefixed)"
    fi
  done
  
  if [ -n "$missing_patterns" ]; then
    TEST_FAILURE_REASON="Stub imps with missing/incorrect patterns: $missing_patterns"
    return 1
  fi
  
  return 0
}

# REQ-ORG-002: Test files must use hyphen naming
test_all_test_files_use_hyphen_naming() {
  # Find any test files using underscores (wrong pattern)
  underscore_tests=$(find "$ROOT_DIR/.tests" -type f -name 'test_*.sh' 2>/dev/null | head -5)
  
  if [ -n "$underscore_tests" ]; then
    count=$(printf '%s' "$underscore_tests" | wc -l)
    examples=$(printf '%s' "$underscore_tests" | head -3 | tr '\n' ', ' | sed 's/, $//')
    TEST_FAILURE_REASON="Found $count test files with underscores (should use hyphens): $examples"
    return 1
  fi
  
  return 0
}

# REQ-META-003: Test output must stream line-by-line
test_test_magic_uses_stdbuf() {
  test_magic_file="$ROOT_DIR/spells/system/test-magic"
  
  # Check if stdbuf is available and used
  if ! command -v stdbuf >/dev/null 2>&1; then
    # stdbuf not available - test is skipped but requirement noted
    return 0
  fi
  
  # Verify test-magic mentions stdbuf
  if ! grep -q "stdbuf" "$test_magic_file"; then
    TEST_FAILURE_REASON="test-magic doesn't use stdbuf for line-buffered output"
    return 1
  fi
  
  return 0
}

# REQ-ERR-001: Test failures must report clearly
test_test_bootstrap_provides_failure_reporting() {
  # Verify TEST_FAILURE_REASON is used in test framework
  if ! grep -q "TEST_FAILURE_REASON" "$ROOT_DIR/spells/.imps/test/boot/"* 2>/dev/null; then
    TEST_FAILURE_REASON="Test framework doesn't support TEST_FAILURE_REASON"
    return 1
  fi
  
  return 0
}

# REQ-IMP-001: die imp must work correctly with word-of-binding
test_die_imp_uses_return_not_exit() {
  die_file="$ROOT_DIR/spells/.imps/out/die"
  
  # Verify die uses return, not exit
  if grep -q "^[[:space:]]*exit " "$die_file"; then
    TEST_FAILURE_REASON="die imp uses 'exit' instead of 'return' (breaks word-of-binding)"
    return 1
  fi
  
  if ! grep -q "^[[:space:]]*return " "$die_file"; then
    TEST_FAILURE_REASON="die imp doesn't use 'return' (required for word-of-binding)"
    return 1
  fi
  
  return 0
}

# REQ-IMP-002: fail imp must NOT exit script
test_fail_imp_returns_error_code() {
  fail_file="$ROOT_DIR/spells/.imps/out/fail"
  
  # Verify fail uses return 1, not exit
  if grep -q "^[[:space:]]*exit " "$fail_file"; then
    TEST_FAILURE_REASON="fail imp uses 'exit' (should use 'return' to continue execution)"
    return 1
  fi
  
  if ! grep -q "return 1" "$fail_file"; then
    TEST_FAILURE_REASON="fail imp doesn't return 1"
    return 1
  fi
  
  return 0
}

# REQ-PLAT-001: Platform detection must work
test_platform_detection_available() {
  # Verify detect-distro spell exists
  if [ ! -f "$ROOT_DIR/spells/divination/detect-distro" ]; then
    TEST_FAILURE_REASON="detect-distro spell not found"
    return 1
  fi
  
  # Verify it's executable
  if [ ! -x "$ROOT_DIR/spells/divination/detect-distro" ]; then
    TEST_FAILURE_REASON="detect-distro is not executable"
    return 1
  fi
  
  return 0
}

# Test that banish spell exists and is the environment preparer
test_banish_spell_exists_and_is_executable() {
  if [ ! -f "$ROOT_DIR/spells/system/banish" ]; then
    TEST_FAILURE_REASON="banish spell not found"
    return 1
  fi
  
  if [ ! -x "$ROOT_DIR/spells/system/banish" ]; then
    TEST_FAILURE_REASON="banish spell is not executable"
    return 1
  fi
  
  # Verify banish has usage that mentions environment preparation
  if ! grep -qi "environment" "$ROOT_DIR/spells/system/banish"; then
    TEST_FAILURE_REASON="banish doesn't mention environment preparation"
    return 1
  fi
  
  return 0
}

# Test that test-bootstrap sources banish or checks environment
test_test_bootstrap_checks_environment() {
  bootstrap_file="$ROOT_DIR/spells/.imps/test/test-bootstrap"
  
  # Check if test-bootstrap mentions banish or environment checking
  # Note: Currently test-bootstrap sets up environment itself
  # This is acceptable as long as it does the work
  
  # Verify it sets up PATH
  if ! grep -q "PATH=" "$bootstrap_file"; then
    TEST_FAILURE_REASON="test-bootstrap doesn't set up PATH"
    return 1
  fi
  
  # Verify it sets up WIZARDRY_DIR
  if ! grep -q "WIZARDRY_DIR" "$bootstrap_file"; then
    TEST_FAILURE_REASON="test-bootstrap doesn't set up WIZARDRY_DIR"
    return 1
  fi
  
  return 0
}

# Run all tests
_run_test_case "REQ-ENV-001: baseline PATH before set -eu" test_bootstrap_sets_baseline_path
_run_test_case "REQ-SAND-005: sandbox fallback is graceful" test_sandbox_fallback_is_graceful
_run_test_case "REQ-STUB-003: stub imps have correct patterns" test_stub_imps_have_correct_self_execute_patterns
_run_test_case "REQ-ORG-002: test files use hyphen naming" test_all_test_files_use_hyphen_naming
_run_test_case "REQ-META-003: test-magic uses stdbuf" test_test_magic_uses_stdbuf
_run_test_case "REQ-ERR-001: test framework supports failure reporting" test_test_bootstrap_provides_failure_reporting
_run_test_case "REQ-IMP-001: die imp uses return for word-of-binding" test_die_imp_uses_return_not_exit
_run_test_case "REQ-IMP-002: fail imp returns error code" test_fail_imp_returns_error_code
_run_test_case "REQ-PLAT-001: platform detection available" test_platform_detection_available
_run_test_case "banish spell exists and is executable" test_banish_spell_exists_and_is_executable
_run_test_case "test-bootstrap checks environment" test_test_bootstrap_checks_environment

_finish_tests
