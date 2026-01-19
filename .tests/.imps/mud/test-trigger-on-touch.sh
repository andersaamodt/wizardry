#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_trigger_on_touch_damage() {
  # Create test directory
  test_tempdir=$(mktemp -d)
  
  # Create toucher and target
  toucher="$test_tempdir/toucher"
  target="$test_tempdir/target.txt"
  printf 'test\n' > "$toucher"
  printf 'test\n' > "$target"
  
  # Add on_toucher effect
  enchant "$toucher" "on_toucher=damage:5" >/dev/null 2>&1
  
  # Trigger effect
  run_spell "spells/.imps/mud/trigger-on-touch" "$toucher" "$target"
  
  # Target should have damage
  damage=$(read-magic "$target" damage 2>/dev/null || printf '0')
  [ "$damage" -ge 5 ] || fail "Expected damage >= 5, got: $damage"
}

test_trigger_on_touch_effect_consumed() {
  # Create test directory
  test_tempdir=$(mktemp -d)
  
  # Create files
  toucher="$test_tempdir/toucher"
  target="$test_tempdir/target.txt"
  printf 'test\n' > "$toucher"
  printf 'test\n' > "$target"
  
  # Add effect
  enchant "$toucher" "on_toucher=damage:3" >/dev/null 2>&1
  
  # Trigger
  run_spell "spells/.imps/mud/trigger-on-touch" "$toucher" "$target"
  
  # Effect should be removed
  effect=$(read-magic "$toucher" on_toucher 2>/dev/null || printf '')
  [ -z "$effect" ] || fail "Effect should be consumed, but got: $effect"
}

run_test_case "trigger-on-touch applies damage effect" test_trigger_on_touch_damage
run_test_case "trigger-on-touch consumes single-use effects" test_trigger_on_touch_effect_consumed
finish_tests
