#!/bin/sh
# Test that no imps have duplicate set -eu statements
# This prevents the bug where sourcing an imp switches invoke-wizardry from permissive to strict mode

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_no_duplicate_set_eu_in_imps() {
  # Find all imp files (excluding test imps and special files)
  imps_dir="$ROOT_DIR/spells/.imps"
  
  _test_pass_count=0
  _test_fail_count=0
  _test_failures=""
  
  # Check all families
  for family in "$imps_dir"/*; do
    [ -d "$family" ] || continue
    
    family_name=$(basename "$family")
    
    # Skip test family - those are only for testing
    case "$family_name" in
      test) continue ;;
    esac
    
    # Check all imps in this family
    for imp_file in "$family"/*; do
      [ -f "$imp_file" ] || continue
      [ -r "$imp_file" ] || continue
      
      imp_name=$(basename "$imp_file")
      
      # Skip special imps
      case "$imp_name" in
        invoke-wizardry|invoke-thesaurus|declare-globals)
          continue
          ;;
      esac
      
      # Count occurrences of "set -eu" at the start of a line
      set_eu_count=$(grep -c "^set -eu" "$imp_file" 2>/dev/null || echo 0)
      
      if [ "$set_eu_count" -gt 1 ]; then
        _test_fail_count=$((_test_fail_count + 1))
        _test_failures="${_test_failures}FAIL: $family_name/$imp_name has $set_eu_count occurrences of 'set -eu'
"
      else
        _test_pass_count=$((_test_pass_count + 1))
      fi
    done
  done
  
  if [ "$_test_fail_count" -gt 0 ]; then
    printf '%s\n' "$_test_failures"
    _test_fail "Found $_test_fail_count imps with duplicate 'set -eu' ($_test_pass_count checked passed)"
    return 1
  fi
  
  _test_pass "All $_test_pass_count imps have at most one 'set -eu' statement"
}

test_imp_set_eu_patterns() {
  # Verify that action imps have set -eu, conditional imps don't
  imps_dir="$ROOT_DIR/spells/.imps"
  
  _conditional_families="cond lex menu"
  _action_families="fs out paths pkg str sys text input lang"
  
  _test_issues=""
  
  # Check conditional families - these should NOT have set -eu
  for family_name in $_conditional_families; do
    family="$imps_dir/$family_name"
    [ -d "$family" ] || continue
    
    for imp_file in "$family"/*; do
      [ -f "$imp_file" ] || continue
      
      imp_name=$(basename "$imp_file")
      
      # Some menu helpers are exceptions
      case "$family_name" in
        menu)
          # Menu helpers that perform actions should have set -eu
          case "$imp_name" in
            render-*|draw-*|show-*) continue ;;
          esac
          ;;
      esac
      
      if grep -q "^set -eu" "$imp_file" 2>/dev/null; then
        _test_issues="${_test_issues}NOTE: Conditional imp $family_name/$imp_name has 'set -eu' (may be intentional)
"
      fi
    done
  done
  
  if [ -n "$_test_issues" ]; then
    printf '%s\n' "$_test_issues"
  fi
  
  _test_pass "Imp set -eu pattern check complete"
}

_run_test_case "no duplicate set -eu in imps" test_no_duplicate_set_eu_in_imps
_run_test_case "imp set -eu patterns" test_imp_set_eu_patterns
_finish_tests
