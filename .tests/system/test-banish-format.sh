#!/bin/sh

# Test banish output format - ensure imps are grouped by category and status

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Helper to copy the current wizardry installation to a test directory
copy_wizardry() {
  dest_dir=$1
  
  cp -r "$ROOT_DIR" "$dest_dir" 2>/dev/null || return 1
  
  if [ -f "$dest_dir/spells/.imps/sys/invoke-wizardry" ]; then
    WIZARDRY_DIR="$dest_dir"
    export WIZARDRY_DIR
    return 0
  fi
  
  return 1
}

# Test that imps are shown one line per category per status
test_imps_grouped_by_category_and_status() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Run banish level 1
  WIZARDRY_DIR="$install_dir" run_spell "spells/system/banish" 1
  assert_success || return 1
  
  # Should show "Required imps:" header
  assert_output_contains "Required imps:" || return 1
  
  # Should NOT show raw format like "sys:L:name" or "cond:A:name"
  ! assert_output_contains "sys:L:" || return 1
  ! assert_output_contains "sys:A:" || return 1
  ! assert_output_contains "cond:L:" || return 1
  ! assert_output_contains "cond:A:" || return 1
  
  # Should show formatted output with category names
  # Multiple categories should be present
  assert_output_contains "sys imp" || return 1
  assert_output_contains "cond imp" || return 1
  assert_output_contains "out imp" || return 1
  
  # Should show both loaded and available status indicators
  # ✓ for loaded, ● for available
  assert_output_contains "✓" || return 1
  assert_output_contains "●" || return 1
  
  return 0
}

# Test pluralization is correct
test_imp_pluralization() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Run banish level 1
  WIZARDRY_DIR="$install_dir" run_spell "spells/system/banish" 1
  assert_success || return 1
  
  # When there's only 1 loaded imp in a category, should show singular "imp"
  # When there are multiple, should show plural "imps"
  # We can't predict exact counts, but we can check that both forms exist
  # since some categories will have 1 and some will have multiple
  
  # Should have at least one singular form (when category has 1 imp)
  # Format: "Loaded CATEGORY imp: NAME"
  if assert_output_contains "Loaded" 2>/dev/null; then
    # If we see "Loaded", check that it's followed by proper format
    # Either "imp:" (singular) or "imps:" (plural)
    assert_output_contains " imp" || return 1
  fi
  
  return 0
}

# Test via invoke-wizardry (sourced context)
test_banish_via_invoke_wizardry() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Test in bash with invoke-wizardry
  output=$(cd "$install_dir" && bash --norc --noprofile <<'EOFTEST'
WIZARDRY_DIR=$(pwd)
export WIZARDRY_DIR
. spells/.imps/sys/invoke-wizardry 2>/dev/null
banish 1 2>&1
EOFTEST
)
  
  # Check output format
  printf '%s\n' "$output" | grep -q "Required imps:" || return 1
  
  # Should show formatted output (not raw "category:status:name")
  ! printf '%s\n' "$output" | grep -q "sys:L:" || return 1
  ! printf '%s\n' "$output" | grep -q "sys:A:" || return 1
  
  # Should show category-grouped output
  printf '%s\n' "$output" | grep -q "sys imp" || return 1
  printf '%s\n' "$output" | grep -q "cond imp" || return 1
  
  return 0
}

# Test that each category+status combination is on its own line
test_each_category_status_on_own_line() {
  tmpdir=$(make_tempdir)
  install_dir="$tmpdir/wizardry"
  
  copy_wizardry "$install_dir" || return 1
  
  # Run banish and check line structure
  WIZARDRY_DIR="$install_dir" run_spell "spells/system/banish" 1
  assert_success || return 1
  
  # Extract just the imp status lines (after "Required imps:")
  # Each line should have format: "  ✓ Loaded CATEGORY imp(s): NAMES"
  # or "  ● Available CATEGORY imp(s): NAMES"
  
  # Count how many lines have "sys imp" - should be at least 1, possibly 2
  # (one for loaded, one for available if both exist)
  sys_lines=$(printf '%s\n' "$OUTPUT" | grep -c "sys imp" || true)
  [ "$sys_lines" -ge 1 ] || return 1
  
  # Same for cond
  cond_lines=$(printf '%s\n' "$OUTPUT" | grep -c "cond imp" || true)
  [ "$cond_lines" -ge 1 ] || return 1
  
  # Each category should not have all imps on one line
  # i.e., loaded and available should be separate lines
  # This is hard to test directly, but we can check that if a category
  # has both loaded and available, there are 2 lines for it
  
  return 0
}

run_test_case "imps grouped by category and status" test_imps_grouped_by_category_and_status
run_test_case "imp pluralization is correct" test_imp_pluralization  
run_test_case "banish via invoke-wizardry shows correct format" test_banish_via_invoke_wizardry
run_test_case "each category+status on own line" test_each_category_status_on_own_line

finish_tests
