#!/bin/sh
# Global checks that apply across all spells and imps.
# Run first as part of test-magic to catch systemic issues early.
#
# This test file implements suite-wide checks that verify properties
# across the entire spellbook rather than testing individual spells.
# Note: POSIX compliance (shebang, bashisms) is checked by verify-posix.

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

# Helper: Check if a file is a POSIX shell script
is_posix_shell_script() {
  file=$1
  first_line=$(head -1 "$file" 2>/dev/null || true)
  case $first_line in
    '#!/bin/sh'|'#! /bin/sh'|'#!/usr/bin/env sh'|'#! /usr/bin/env sh') return 0 ;;
    *) return 1 ;;
  esac
}

# Helper: Check if a file is any shell script (including bash)
is_any_shell_script() {
  file=$1
  first_line=$(head -1 "$file" 2>/dev/null || true)
  case $first_line in
    '#!/bin/sh'|'#! /bin/sh'|'#!/usr/bin/env sh'|'#! /usr/bin/env sh') return 0 ;;
    '#!/bin/bash'|'#! /bin/bash'|'#!/usr/bin/env bash'|'#! /usr/bin/env bash') return 0 ;;
    *) return 1 ;;
  esac
}

# Helper: Check if file should be skipped
should_skip_file() {
  name=$1
  case $name in
    .gitkeep|.gitignore|*.service|*.md) return 0 ;;
    *) return 1 ;;
  esac
}

# --- Check: No duplicate spell names ---
# All spells (including imps) must have unique names since they share PATH

test_no_duplicate_spell_names() {
  # Collect all spell and imp names
  names_file=$(mktemp "${WIZARDRY_TMPDIR}/spell-names.XXXXXX")
  
  # Find all executable files in spells/ (including .imps)
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    
    # Include all shell scripts (POSIX and bash) since they share PATH
    is_any_shell_script "$spell" || continue
    
    printf '%s\n' "$name"
  done | sort > "$names_file"
  
  # Check for duplicates
  duplicates=$(uniq -d "$names_file" || true)
  rm -f "$names_file"
  
  if [ -n "$duplicates" ]; then
    TEST_FAILURE_REASON="duplicate spell names found: $duplicates"
    return 1
  fi
  return 0
}

# --- Check: All menu spells require the menu command ---
# Menu spells in spells/menu/ should check for menu dependency

test_menu_spells_require_menu() {
  missing_require=""
  
  for menu_spell in "$ROOT_DIR"/spells/menu/*; do
    [ -f "$menu_spell" ] || continue
    name=$(basename "$menu_spell")
    
    # Skip spells that are not actual menus (cast and spellbook check memorize instead)
    # and priorities which is a different pattern
    case $name in
      cast|spellbook|priorities|network-menu) continue ;;
    esac
    
    # Check if spell contains "require menu" or "require_tool menu" pattern
    if ! grep -qE 'require(_tool)? menu' "$menu_spell" 2>/dev/null; then
      missing_require="${missing_require:+$missing_require, }$name"
    fi
  done
  
  if [ -n "$missing_require" ]; then
    TEST_FAILURE_REASON="menu spells missing 'require menu' check: $missing_require"
    return 1
  fi
  return 0
}

# --- Check: All spells have description comment ---
# Every spell should have a description comment after the shebang

test_all_spells_have_description() {
  missing_desc=""
  
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
    # Check lines 2-4 for a comment (description should be in first few lines)
    # Use grep to check for comment lines in lines 2-4
    if sed -n '2p;3p;4p' "$spell" 2>/dev/null | grep -q '^#'; then
      : # Has comment, skip
    else
      printf '%s\n' "$name"
    fi
  done > "${WIZARDRY_TMPDIR}/missing-desc.txt"
  
  missing_desc=$(cat "${WIZARDRY_TMPDIR}/missing-desc.txt" 2>/dev/null | head -5 | tr '\n' ', ' | sed 's/,$//')
  rm -f "${WIZARDRY_TMPDIR}/missing-desc.txt"
  
  if [ -n "$missing_desc" ]; then
    TEST_FAILURE_REASON="spells missing description comment: $missing_desc"
    return 1
  fi
  return 0
}

# --- Warning Check: No full paths to spell names in non-bootstrap spells ---
# Spells should invoke other spells by name, not full path (except bootstrap spells)

test_warn_full_paths_to_spells() {
  found_paths=""
  
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    # Skip bootstrap spells (install/core/) and test-magic
    case $spell in
      */install/core/*|*/system/test-magic) continue ;;
    esac
    
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
    # Check for patterns like $ROOT_DIR/spells/ or absolute paths to spells
    # excluding comments and variable definitions
    if grep -E '\$ROOT_DIR/spells/|\$ABS_DIR/spells/' "$spell" 2>/dev/null | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*[A-Z_]*=' | grep -q .; then
      printf '%s\n' "$name"
    fi
  done > "${WIZARDRY_TMPDIR}/full-paths.txt"
  
  found_paths=$(cat "${WIZARDRY_TMPDIR}/full-paths.txt" 2>/dev/null | sort -u | tr '\n' ', ' | sed 's/,$//')
  rm -f "${WIZARDRY_TMPDIR}/full-paths.txt"
  
  if [ -n "$found_paths" ]; then
    printf 'WARNING: spells using full paths to invoke other spells (should use name only): %s\n' "$found_paths" >&2
  fi
  return 0
}

# --- Check: Non-imp spells have set -e or set -eu ---
# All spells (except imps, which may use exit codes for flow) should have strict mode

test_spells_use_strict_mode() {
  missing_strict=""
  
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    # Skip imps (they may legitimately not use set -e)
    case $spell in
      */.imps/*) continue ;;
    esac
    
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
    # Check for set -e anywhere in the file
    if ! grep -qE 'set -e' "$spell" 2>/dev/null; then
      printf '%s\n' "$name"
    fi
  done > "${WIZARDRY_TMPDIR}/no-strict.txt"
  
  missing_strict=$(cat "${WIZARDRY_TMPDIR}/no-strict.txt" 2>/dev/null | head -5 | tr '\n' ', ' | sed 's/,$//')
  rm -f "${WIZARDRY_TMPDIR}/no-strict.txt"
  
  if [ -n "$missing_strict" ]; then
    TEST_FAILURE_REASON="spells missing strict mode (set -e or set -eu): $missing_strict"
    return 1
  fi
  return 0
}

# --- Check: Test files mirror spell structure ---
# Each test file should correspond to a spell (covered by test-magic, but good to verify)

test_test_files_have_matching_spells() {
  orphan_tests=""
  
  find "$ROOT_DIR/.tests" -type f -name 'test-*.sh' -print | while IFS= read -r test_file; do
    # Skip special files
    case $test_file in
      */test-common.sh|*/test-install.sh|*/test-global-checks.sh|*/lib/*) continue ;;
    esac
    
    # Extract expected spell path
    rel=${test_file#"$ROOT_DIR/.tests/"}
    dir=$(dirname "$rel")
    base=$(basename "$rel")
    base=${base#test-}
    base=${base%.sh}
    
    # Handle root-level install test
    case "$base" in
      install|install-with-old-version)
        if [ "$dir" = "." ] || [ "$dir" = "install" ]; then
          if [ -f "$ROOT_DIR/install" ]; then
            continue
          fi
        fi
        ;;
    esac
    
    spell_path="$ROOT_DIR/spells/$dir/$base"
    if [ ! -f "$spell_path" ]; then
      printf '%s\n' "$rel"
    fi
  done > "${WIZARDRY_TMPDIR}/orphan-tests.txt"
  
  orphan_tests=$(cat "${WIZARDRY_TMPDIR}/orphan-tests.txt" 2>/dev/null | head -5 | tr '\n' ', ' | sed 's/,$//')
  rm -f "${WIZARDRY_TMPDIR}/orphan-tests.txt"
  
  if [ -n "$orphan_tests" ]; then
    TEST_FAILURE_REASON="test files with no matching spell: $orphan_tests"
    return 1
  fi
  return 0
}

# --- Warning Check: Spell and imp names should follow naming convention ---
# Spells and imps should use hyphens (not underscores) and have no extension

test_warn_spell_naming() {
  bad_names=""
  
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print 2>/dev/null | while IFS= read -r spell; do
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
    # Check for underscore in name (should use hyphens)
    case $name in
      *_*) printf '%s (uses underscore)\n' "$name" ;;
    esac
    
    # Check for .sh extension (spells shouldn't have extensions)
    case $name in
      *.sh) printf '%s (has .sh extension)\n' "$name" ;;
    esac
  done > "${WIZARDRY_TMPDIR}/bad-spell-names.txt"
  
  bad_names=$(cat "${WIZARDRY_TMPDIR}/bad-spell-names.txt" 2>/dev/null | head -5 | tr '\n' ', ' | sed 's/,$//')
  rm -f "${WIZARDRY_TMPDIR}/bad-spell-names.txt"
  
  if [ -n "$bad_names" ]; then
    # Warning only - there are pre-existing spells with underscores
    printf 'WARNING: spells with non-standard naming (prefer hyphens, no extension): %s\n' "$bad_names" >&2
  fi
  return 0
}

# --- Warning Check: Global variables in spells ---
# Spells should minimize use of global/environment variables per AGENTS.md

test_warn_global_variables() {
  # This check warns about shell variables that appear to be global
  # (uppercase names that are declared or used without being local)
  # Excludes well-known environment variables and common patterns
  
  # Known acceptable global variables (environment, special, or standard)
  # These are either read from environment or are standard shell variables
  known_vars="HOME|PATH|PWD|OLDPWD|USER|SHELL|TERM|LANG|LC_ALL|LC_CTYPE"
  known_vars="$known_vars|TMPDIR|XDG_CONFIG_HOME|XDG_DATA_HOME|XDG_CACHE_HOME"
  known_vars="$known_vars|EDITOR|VISUAL|PAGER|BROWSER|DISPLAY"
  known_vars="$known_vars|IFS|PS1|PS2|PS4|CDPATH"
  known_vars="$known_vars|WIZARDRY_[A-Z_]*"  # Wizardry-specific env vars
  known_vars="$known_vars|GITHUB_[A-Z_]*"    # CI environment
  known_vars="$known_vars|CI|RUNNER_[A-Z_]*" # CI environment
  known_vars="$known_vars|STATUS|OUTPUT|ERROR"  # Test framework variables
  known_vars="$known_vars|ROOT_DIR|RESET|CYAN|GREY|PURPLE|YELLOW|BLUE|RED|GREEN"  # Colors and test vars
  known_vars="$known_vars|TEST_[A-Z_]*"      # Test variables
  
  vars_found=""
  
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
    # Find uppercase variable assignments (VAR=value or VAR=$(cmd))
    # Exclude function-local patterns and known variables
    grep -oE '^[[:space:]]*[A-Z][A-Z0-9_]*=' "$spell" 2>/dev/null | \
      sed 's/^[[:space:]]*//; s/=$//' | \
      grep -vE "^($known_vars)$" | \
      while IFS= read -r var; do
        [ -n "$var" ] && printf '%s:%s\n' "$name" "$var"
      done
  done > "${WIZARDRY_TMPDIR}/global-vars.txt"
  
  # Count unique spells with global variables
  spells_with_globals=$(cut -d: -f1 "${WIZARDRY_TMPDIR}/global-vars.txt" 2>/dev/null | sort -u | head -10 | tr '\n' ', ' | sed 's/,$//')
  rm -f "${WIZARDRY_TMPDIR}/global-vars.txt"
  
  if [ -n "$spells_with_globals" ]; then
    printf 'WARNING: spells declaring uppercase variables (consider using parameters/stdout instead): %s\n' "$spells_with_globals" >&2
  fi
  return 0
}

# --- Run all test cases ---

run_test_case "no duplicate spell names" test_no_duplicate_spell_names
run_test_case "menu spells require menu command" test_menu_spells_require_menu
run_test_case "all spells have description comment" test_all_spells_have_description
run_test_case "warn about full paths to spells" test_warn_full_paths_to_spells
run_test_case "spells use strict mode" test_spells_use_strict_mode
run_test_case "test files have matching spells" test_test_files_have_matching_spells
run_test_case "warn about spell naming" test_warn_spell_naming
run_test_case "warn about global variables" test_warn_global_variables

finish_tests
