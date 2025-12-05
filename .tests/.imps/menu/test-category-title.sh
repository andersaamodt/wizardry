#!/bin/sh
# Tests for category-title imp

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_enchant_becomes_enchantment() {
  _run_spell "spells/.imps/menu/category-title" "enchant"
  _assert_success || return 1
  case "$OUTPUT" in
    *Enchantment*) : ;;
    *) TEST_FAILURE_REASON="expected 'Enchantment' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_mud_becomes_uppercase() {
  _run_spell "spells/.imps/menu/category-title" "mud"
  _assert_success || return 1
  case "$OUTPUT" in
    *MUD*) : ;;
    *) TEST_FAILURE_REASON="expected 'MUD' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_arcane_capitalizes() {
  _run_spell "spells/.imps/menu/category-title" "arcane"
  _assert_success || return 1
  case "$OUTPUT" in
    *Arcane*) : ;;
    *) TEST_FAILURE_REASON="expected 'Arcane' but got '$OUTPUT'"; return 1 ;;
  esac
}

test_unknown_capitalizes_first() {
  _run_spell "spells/.imps/menu/category-title" "unknown-category"
  _assert_success || return 1
  case "$OUTPUT" in
    *Unknown-category*) : ;;
    *) TEST_FAILURE_REASON="expected 'Unknown-category' but got '$OUTPUT'"; return 1 ;;
  esac
}

_run_test_case "enchant becomes Enchantment" test_enchant_becomes_enchantment
_run_test_case "mud becomes MUD" test_mud_becomes_uppercase
_run_test_case "arcane becomes Arcane" test_arcane_capitalizes
_run_test_case "unknown categories capitalize first letter" test_unknown_capitalizes_first

_finish_tests
