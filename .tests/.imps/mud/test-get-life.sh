#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Create stub xattr helper

test_get_life_no_damage() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test\n' > "$test_file"
  
  stub-xattr "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Set max_life
  "$stub_dir/xattr" -w user.max_life 100 "$test_file"
  
  output=$(get-life "$test_file")
  [ "$output" = "100" ] || fail "Expected life=100, got $output"
}

test_get_life_with_damage() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test\n' > "$test_file"
  
  stub-xattr "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Set max_life and damage
  "$stub_dir/xattr" -w user.max_life 100 "$test_file"
  "$stub_dir/xattr" -w user.damage 30 "$test_file"
  
  output=$(get-life "$test_file")
  [ "$output" = "70" ] || fail "Expected life=70, got $output"
}

test_get_life_dead() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test\n' > "$test_file"
  
  stub-xattr "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Set damage >= max_life
  "$stub_dir/xattr" -w user.max_life 100 "$test_file"
  "$stub_dir/xattr" -w user.damage 150 "$test_file"
  
  output=$(get-life "$test_file")
  [ "$output" = "0" ] || fail "Expected life=0, got $output"
}

test_deal_damage_basic() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test\n' > "$test_file"
  
  stub-xattr "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  deal-damage "$test_file" 25
  
  damage=$("$stub_dir/xattr" -p user.damage "$test_file")
  [ "$damage" = "25" ] || fail "Expected damage=25, got $damage"
}

test_deal_damage_accumulates() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test\n' > "$test_file"
  
  stub-xattr "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  deal-damage "$test_file" 25
  deal-damage "$test_file" 15
  
  damage=$("$stub_dir/xattr" -p user.damage "$test_file")
  [ "$damage" = "40" ] || fail "Expected damage=40, got $damage"
}

test_deal_damage_marks_dead() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test\n' > "$test_file"
  
  stub-xattr "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Set max_life and deal lethal damage
  "$stub_dir/xattr" -w user.max_life 100 "$test_file"
  deal-damage "$test_file" 150
  
  dead=$("$stub_dir/xattr" -p user.dead "$test_file")
  [ "$dead" = "1" ] || fail "Expected dead=1, got $dead"
}

run_test_case "get-life returns full health with no damage" test_get_life_no_damage
run_test_case "get-life calculates current life with damage" test_get_life_with_damage
run_test_case "get-life returns 0 when dead" test_get_life_dead
run_test_case "deal-damage applies damage" test_deal_damage_basic
run_test_case "deal-damage accumulates" test_deal_damage_accumulates
run_test_case "deal-damage marks target as dead" test_deal_damage_marks_dead

finish_tests
