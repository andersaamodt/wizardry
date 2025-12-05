#!/bin/sh
# Tests for category-title imp

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_enchant_becomes_enchantment() {
  run_spell "spells/.imps/menu/category-title" "enchant"
  assert_success || return 1
  case "$OUTPUT" in
    *Enchantment*) : ;;
    *) TEST_FAILURE_REASON="expected 'Enchantment' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_mud_becomes_uppercase() {
  run_spell "spells/.imps/menu/category-title" "mud"
  assert_success || return 1
  case "$OUTPUT" in
    *MUD*) : ;;
    *) TEST_FAILURE_REASON="expected 'MUD' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_arcane_capitalizes() {
  run_spell "spells/.imps/menu/category-title" "arcane"
  assert_success || return 1
  case "$OUTPUT" in
    *Arcane*) : ;;
    *) TEST_FAILURE_REASON="expected 'Arcane' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_unknown_capitalizes_first() {
  run_spell "spells/.imps/menu/category-title" "unknown-category"
  assert_success || return 1
  case "$OUTPUT" in
    *Unknown-category*) : ;;
    *) TEST_FAILURE_REASON="expected 'Unknown-category' but got '$OUTPUT'"; return 1 ;;
  esac
}

run_test_case "enchant becomes Enchantment" test_enchant_becomes_enchantment
run_test_case "mud becomes MUD" test_mud_becomes_uppercase
run_test_case "arcane becomes Arcane" test_arcane_capitalizes
run_test_case "unknown categories capitalize first letter" test_unknown_capitalizes_first

finish_tests
