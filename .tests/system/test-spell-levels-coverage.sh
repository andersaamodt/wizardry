#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_no_empty_levels() {
  # Source spell-levels to get the function
  . "$ROOT_DIR/spells/.imps/sys/spell-levels"
  
  empty_levels=""
  for level in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28; do
    spells=$(spell_levels "$level" spells 2>/dev/null || echo "ERROR")
    imps=$(spell_levels "$level" imps 2>/dev/null || echo "ERROR")
    name=$(spell_levels "$level" name 2>/dev/null || echo "ERROR")
    
    if [ "$spells" = "ERROR" ]; then
      empty_levels="${empty_levels}Level $level: ERROR getting data\n"
    elif [ -z "$spells" ] && [ -z "$imps" ]; then
      empty_levels="${empty_levels}Level $level ($name): EMPTY\n"
    fi
  done
  
  if [ -n "$empty_levels" ]; then
    printf "Found empty levels:\n%b" "$empty_levels" >&2
    return 1
  fi
  return 0
}

test_all_spells_categorized() {
  # Source spell-levels
  . "$ROOT_DIR/spells/.imps/sys/spell-levels"
  
  # Get all spells from spell-levels (strip category suffix)
  spells_in_levels=""
  for level in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28; do
    level_spells=$(spell_levels "$level" spells 2>/dev/null)
    if [ -n "$level_spells" ]; then
      spells_in_levels="$spells_in_levels $level_spells"
    fi
  done
  
  # Convert to sorted list of unique spell names (strip :category suffix)
  spells_in_levels=$(printf '%s' "$spells_in_levels" | tr ' ' '\n' | sed 's/:.*$//' | grep -v '^$' | sort -u)
  
  # Get all actual spell files
  actual_spells=$(find "$ROOT_DIR/spells" -type f ! -path '*/.*' ! -path '*/.imps/*' -exec basename {} \; | sort -u)
  
  # Find spells not in levels
  uncategorized=""
  for spell in $actual_spells; do
    if ! printf '%s\n' "$spells_in_levels" | grep -q "^${spell}$"; then
      uncategorized="${uncategorized}${spell}\n"
    fi
  done
  
  if [ -n "$uncategorized" ]; then
    printf "Spells not categorized in spell-levels:\n%b" "$uncategorized" >&2
    return 1
  fi
  return 0
}

test_all_imps_categorized() {
  # Source spell-levels
  . "$ROOT_DIR/spells/.imps/sys/spell-levels"
  
  # Get all imps from spell-levels (strip path prefix)
  imps_in_levels=""
  for level in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28; do
    level_imps=$(spell_levels "$level" imps 2>/dev/null)
    if [ -n "$level_imps" ]; then
      imps_in_levels="$imps_in_levels $level_imps"
    fi
  done
  
  # Convert to sorted list of unique imp names (strip directory prefix)
  imps_in_levels=$(printf '%s' "$imps_in_levels" | tr ' ' '\n' | sed 's|^.*/||' | grep -v '^$' | sort -u)
  
  # Get all actual imp files (excluding test imps and .gitkeep)
  actual_imps=$(find "$ROOT_DIR/spells/.imps" -type f ! -path '*/test/*' ! -name '.gitkeep' -exec basename {} \; | sort -u)
  
  # Find imps not in levels
  uncategorized=""
  for imp in $actual_imps; do
    if ! printf '%s\n' "$imps_in_levels" | grep -q "^${imp}$"; then
      uncategorized="${uncategorized}${imp}\n"
    fi
  done
  
  if [ -n "$uncategorized" ]; then
    printf "Imps not categorized in spell-levels:\n%b" "$uncategorized" >&2
    return 1
  fi
  return 0
}

run_test_case "spell-levels has no empty levels" test_no_empty_levels
run_test_case "all spells are categorized in spell-levels" test_all_spells_categorized  
run_test_case "all imps are categorized in spell-levels" test_all_imps_categorized

finish_tests
