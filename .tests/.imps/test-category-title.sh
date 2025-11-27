#!/bin/sh
# Tests for category-title imp

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_enchant_becomes_enchantment() {
  run_spell "spells/.imps/category-title" "enchant"
  assert_success || return 1
  case "$OUTPUT" in
    *Enchantment*) : ;;
    *) TEST_FAILURE_REASON="expected 'Enchantment' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_mud_becomes_uppercase() {
  run_spell "spells/.imps/category-title" "mud"
  assert_success || return 1
  case "$OUTPUT" in
    *MUD*) : ;;
    *) TEST_FAILURE_REASON="expected 'MUD' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_mud_admin_title() {
  run_spell "spells/.imps/category-title" "mud-admin"
  assert_success || return 1
  case "$OUTPUT" in
    *"MUD Admin"*) : ;;
    *) TEST_FAILURE_REASON="expected 'MUD Admin' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_arcane_capitalizes() {
  run_spell "spells/.imps/category-title" "arcane"
  assert_success || return 1
  case "$OUTPUT" in
    *Arcane*) : ;;
    *) TEST_FAILURE_REASON="expected 'Arcane' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_unknown_capitalizes_first() {
  run_spell "spells/.imps/category-title" "unknown-category"
  assert_success || return 1
  case "$OUTPUT" in
    *Unknown-category*) : ;;
    *) TEST_FAILURE_REASON="expected 'Unknown-category' but got '$OUTPUT'"; return 1 ;;
  esac
}

run_test_case "enchant becomes Enchantment" test_enchant_becomes_enchantment
run_test_case "mud becomes MUD" test_mud_becomes_uppercase
run_test_case "mud-admin becomes MUD Admin" test_mud_admin_title
run_test_case "arcane becomes Arcane" test_arcane_capitalizes
run_test_case "unknown categories capitalize first letter" test_unknown_capitalizes_first

finish_tests
