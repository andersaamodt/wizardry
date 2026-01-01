#!/bin/sh

# Test to verify spell level coverage - ensures every spell is in exactly one level

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Extract spell lists from banish for all levels 0-27
get_all_spells_from_levels() {
  level=0
  while [ "$level" -le 27 ]; do
    # Source banish and call get_level_spells
    cd "$ROOT_DIR" && ./spells/system/banish --help >/dev/null 2>&1
    # Extract spell definitions by parsing the get_level_spells function
    spells=$(sed -n "/^get_level_spells/,/^}/p" "$ROOT_DIR/spells/system/banish" | \
             sed -n "/$level) printf '/s/.*printf '//;s/' ;;//p")
    
    if [ -n "$spells" ]; then
      # Parse spell:dir format and plain names
      for spell_info in $spells; do
        case "$spell_info" in
          *:*)
            spell=$(printf '%s' "$spell_info" | cut -d: -f1)
            dir=$(printf '%s' "$spell_info" | cut -d: -f2)
            ;;
          *)
            spell=$spell_info
            dir="cantrips"
            ;;
        esac
        printf '%s:%s:%d\n' "$spell" "$dir" "$level"
      done
    fi
    
    level=$((level + 1))
  done
}

# Get all actual spells in the repository
get_all_actual_spells() {
  find "$ROOT_DIR/spells" -type f -not -path "*/.*" -not -path "*/.imps/*" | while read -r spell_path; do
    spell=$(basename "$spell_path")
    dir=$(dirname "$spell_path" | sed "s|$ROOT_DIR/spells/||")
    printf '%s:%s\n' "$spell" "$dir"
  done | sort
}

test_no_duplicate_spells() {
  all_spells=$(get_all_spells_from_levels)
  
  # Check for duplicates
  duplicates=$(printf '%s\n' "$all_spells" | cut -d: -f1,2 | sort | uniq -d)
  
  if [ -n "$duplicates" ]; then
    printf 'Found spells in multiple levels:\n'
    printf '%s\n' "$duplicates"
    return 1
  fi
  
  _assert_success
}

test_all_spells_covered() {
  level_spells=$(get_all_spells_from_levels | cut -d: -f1,2 | sort -u)
  actual_spells=$(get_all_actual_spells)
  
  # Find spells not in any level (excluding special cases)
  missing=""
  for actual in $actual_spells; do
    spell=$(printf '%s' "$actual" | cut -d: -f1)
    dir=$(printf '%s' "$actual" | cut -d: -f2)
    
    # Skip install script (bootstrap, not a regular spell)
    [ "$spell" = "install" ] && continue
    # Skip scripts in install/core (bootstrap scripts)
    case "$dir" in
      install/core) continue ;;
    esac
    
    # Check if this spell is in level_spells
    found=0
    for level_spell in $level_spells; do
      if [ "$actual" = "$level_spell" ]; then
        found=1
        break
      fi
    done
    
    if [ "$found" -eq 0 ]; then
      missing="${missing:+$missing\n}$actual"
    fi
  done
  
  if [ -n "$missing" ]; then
    printf 'Spells not assigned to any level:\n'
    printf '%s\n' "$missing"
    return 1
  fi
  
  _assert_success
}

_run_test_case "no spell appears in multiple levels" test_no_duplicate_spells
_run_test_case "all spells are assigned to a level" test_all_spells_covered

_finish_tests
