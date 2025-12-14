#!/bin/sh

# Test for function name collisions when sourcing spells via invoke-wizardry
# This test ensures no two spells define the same function names

set -eu

repo_dir=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd -P)

# Track function definitions
declare_functions=""
collision_found=0

check_collision() {
  func_name=$1
  source_file=$2
  
  # Check if already seen
  if printf '%s\n' "$declare_functions" | grep -q "^${func_name}:"; then
    # Collision detected
    prev_file=$(printf '%s\n' "$declare_functions" | grep "^${func_name}:" | head -1 | cut -d: -f2-)
    printf 'COLLISION: Function %s defined in both:\n' "$func_name" >&2
    printf '  - %s\n' "$prev_file" >&2
    printf '  - %s\n' "$source_file" >&2
    collision_found=1
  else
    # Record this function
    declare_functions="${declare_functions}${func_name}:${source_file}
"
  fi
}

# Check all executable spells
for spell_dir in "$repo_dir"/spells/*; do
  [ -d "$spell_dir" ] || continue
  case "$spell_dir" in
    */.imps|*/.arcana) continue ;;
  esac
  
  for spell in "$spell_dir"/*; do
    [ -f "$spell" ] && [ -x "$spell" ] || continue
    
    # Extract function names (looking for function_name() {)
    while IFS= read -r line; do
      if printf '%s' "$line" | grep -qE '^[a-zA-Z_][a-zA-Z0-9_]*\(\)[[:space:]]*\{'; then
        func_name=$(printf '%s' "$line" | sed 's/()[[:space:]]*{.*//')
        check_collision "$func_name" "$spell"
      fi
    done < "$spell"
  done
done

# Check imps for underscore-prefixed functions
for imp_family in "$repo_dir"/spells/.imps/*; do
  [ -d "$imp_family" ] || continue
  for imp in "$imp_family"/*; do
    [ -f "$imp" ] && [ -x "$imp" ] || continue
    
    while IFS= read -r line; do
      if printf '%s' "$line" | grep -qE '^_[a-zA-Z_][a-zA-Z0-9_]*\(\)[[:space:]]*\{'; then
        func_name=$(printf '%s' "$line" | sed 's/()[[:space:]]*{.*//')
        check_collision "$func_name" "$imp"
      fi
    done < "$imp"
  done
done

if [ "$collision_found" -eq 1 ]; then
  printf '\nERROR: Function name collisions detected!\n' >&2
  exit 1
else
  printf 'PASS: No function name collisions found\n'
  exit 0
fi

