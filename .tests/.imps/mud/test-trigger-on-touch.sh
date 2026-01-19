#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_trigger_on_touch_toucher_effect() {
  _test_setup_mud_env
  
  # Create toucher and touched files
  toucher="$test_dir/toucher"
  touched="$test_dir/touched"
  mkdir -p "$toucher"
  touch "$touched"
  
  # Add on_toucher effect to toucher
  enchant "$toucher" "on_toucher=damage:4" >/dev/null 2>&1 || true
  enchant "$touched" "max_life=100" >/dev/null 2>&1 || true
  
  # Trigger on-touch
  trigger-on-touch "$toucher" "$touched" >/dev/null 2>&1 || true
  
  # Verify damage was dealt
  damage=$(read-magic "$touched" damage 2>/dev/null || printf '0')
  [ "$damage" = "4" ] || _fail "Expected damage=4, got: $damage"
  
  # Verify effect was removed from toucher
  on_toucher=$(read-magic "$toucher" on_toucher 2>/dev/null || printf '')
  [ -z "$on_toucher" ] || _fail "Expected on_toucher to be removed, got: $on_toucher"
}

test_trigger_on_touch_touched_portkey() {
  _test_setup_mud_env
  
  # Create toucher and portkey
  toucher="$test_dir/toucher"
  portkey="$test_dir/portkey"
  dest="$test_dir/destination"
  mkdir -p "$toucher" "$dest"
  touch "$portkey"
  
  # Add on_touched portkey effect
  enchant "$portkey" "on_touched=portkey:$dest" >/dev/null 2>&1 || true
  
  # Trigger on-touch
  output=$(trigger-on-touch "$toucher" "$portkey" 2>&1 || true)
  
  # Verify portkey activation message
  printf '%s\n' "$output" | grep -q "portkey activates" || _fail "Expected portkey activation message"
}

_run_test_case "trigger-on-touch processes toucher damage effect" test_trigger_on_touch_toucher_effect
_run_test_case "trigger-on-touch activates portkey on touched object" test_trigger_on_touch_touched_portkey
_finish_tests
