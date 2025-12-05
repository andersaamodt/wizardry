#!/bin/sh
# Global checks that apply across all spells and imps.
# Run first as part of test-magic to catch systemic issues early.
#
# This test file implements behavioral and structural checks that verify
# properties across the entire spellbook. Style/opinionated checks belong
# in vet-spell instead.
# Note: POSIX compliance (shebang, bashisms) is checked by verify-posix.

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

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
# This is a structural check - prevents PATH conflicts

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
# This is a behavioral check - applies to specific category of spells

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

# --- Check: Spells expose standardized help handlers ---
# Ensure each spell provides show_usage() and a --help|--usage|-h) case
test_spells_have_help_usage_handlers() {
  missing_usage=""
  missing_handler=""

  find "$ROOT_DIR/spells" -type f -not -path "*/.imps/*" -print | while IFS= read -r spell; do
    base_name=$(basename "$spell")
    should_skip_file "$base_name" && continue
    is_posix_shell_script "$spell" || continue

    rel_path=${spell#"$ROOT_DIR/spells/"}

    if ! grep -qE '^[[:space:]]*show_usage\(\)' "$spell" 2>/dev/null; then
      missing_usage="${missing_usage:+$missing_usage, }$rel_path"
      continue
    fi

    if ! grep -qF -- '--help|--usage|-h)' "$spell" 2>/dev/null; then
      missing_handler="${missing_handler:+$missing_handler, }$rel_path"
    fi
  done

  if [ -n "$missing_usage" ]; then
    TEST_FAILURE_REASON="missing show_usage(): $missing_usage"
    return 1
  fi

  if [ -n "$missing_handler" ]; then
    TEST_FAILURE_REASON="missing --help|--usage|-h handler: $missing_handler"
    return 1
  fi

  return 0
}

# --- Warning Check: No full paths to spell names in non-bootstrap spells ---
# Spells should invoke other spells by name, not full path (except bootstrap spells)
# This is a behavioral check - enforces wizardry design principle

test_warn_full_paths_to_spells() {
  found_paths=""
  
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    # Skip bootstrap spells (install/core/), test-magic, and the spellbook menu.
    # Those scripts need repo-root paths to assemble PATH or locate user spells,
    # while normal spells should rely on PATH lookups.
    case $spell in
      */install/core/*|*/system/test-magic) continue ;;
      */.imps/test/test-bootstrap|*/menu/spellbook) continue ;;
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

# --- Check: Test files mirror spell structure ---
# Each test file should correspond to a spell
# This is a structural check - maintains test suite integrity

test_test_files_have_matching_spells() {
  orphan_tests=""
  
  find "$ROOT_DIR/.tests" -type f -name 'test-*.sh' -print | while IFS= read -r test_file; do
    # Skip special files
    case $test_file in
      */spells/.imps/test/test-bootstrap|*/test-install.sh|*/test-suite.sh) continue ;;
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

# --- Check: Tests rely on imps rather than shared helper libraries ---
# There should be no reusable test helpers outside .imps/. Instead, every
# shell script under .tests/ is expected to be a test (starting with test-).
test_tests_use_imps_for_helpers() {
  helper_dir_list=$(mktemp "${WIZARDRY_TMPDIR}/tests-helper-dirs.XXXXXX")
  find "$ROOT_DIR/.tests" -type d \
    \( -name "lib" -o -name "libs" -o -name "common" -o -name "helpers" \) \
    -print > "$helper_dir_list"

  forbidden_dirs=""
  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    rel_dir=${dir#"$ROOT_DIR/"}
    forbidden_dirs="${forbidden_dirs:+$forbidden_dirs, }$rel_dir"
  done < "$helper_dir_list"
  rm -f "$helper_dir_list"

  if [ -n "$forbidden_dirs" ]; then
    TEST_FAILURE_REASON="legacy test helper directories present: $forbidden_dirs"
    return 1
  fi

  helper_files_list=$(mktemp "${WIZARDRY_TMPDIR}/tests-helper-files.XXXXXX")
  find "$ROOT_DIR/.tests" -type f -not -path "*/.imps/*" -print > "$helper_files_list"

  invalid_helpers=""
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    base=$(basename "$file")
    should_skip_file "$base" && continue
    is_any_shell_script "$file" || continue

    case $base in
      test-*) ;;
      *)
        rel_file=${file#"$ROOT_DIR/"}
        invalid_helpers="${invalid_helpers:+$invalid_helpers, }$rel_file"
        ;;
    esac
  done < "$helper_files_list"
  rm -f "$helper_files_list"

  if [ -n "$invalid_helpers" ]; then
    TEST_FAILURE_REASON="non-imp shared test helpers detected: $invalid_helpers"
    return 1
  fi

  return 0
}

declared_globals() {
  if [ ! -f "$ROOT_DIR/spells/.imps/declare-globals" ]; then
    return 1
  fi

  # Extract variable names from lines like ': "${NAME:=}"'
  sed -n 's/^: "\${\([A-Z0-9_]*\):=.*/\1/p' "$ROOT_DIR/spells/.imps/declare-globals"
}

# Scripts that intentionally rely on globals must opt into set -u to fail fast
# when globals are missing. We detect scripts that source declare-globals and
# ensure they enable unset-variable checking near the top of the file.
test_scripts_using_globals_have_set_u() {
  offenders=""

  find "$ROOT_DIR/spells" -type f -not -path "*/.imps/*" -print | while IFS= read -r spell; do
    is_posix_shell_script "$spell" || continue
    grep -q "declare-globals" "$spell" 2>/dev/null || continue

    if ! head -n 15 "$spell" | grep -q "set -u"; then
      offenders="${offenders:+$offenders, }${spell#"$ROOT_DIR/"}"
    fi
  done

  if [ -n "$offenders" ]; then
    TEST_FAILURE_REASON="scripts using declare-globals without set -u: $offenders"
    return 1
  fi
  return 0
}

# Guard the centralized list of globals so new additions stay intentional.
test_declare_globals_count() {
  globals=$(declared_globals | sort)
  count=$(printf '%s\n' "$globals" | sed '/^$/d' | wc -l | tr -d ' ')
  expected="MUD_DIR
SPELLBOOK_DIR
WIZARDRY_DIR"

  if [ "$count" -ne 3 ] || [ "$globals" != "$expected" ]; then
    TEST_FAILURE_REASON="declare-globals must define exactly MUD_DIR, SPELLBOOK_DIR, and WIZARDRY_DIR"
    return 1
  fi
  return 0
}

# Ensure exports stay limited to declared globals to avoid leaking new
# environment variables.
test_no_undeclared_global_exports() {
  allowed=$(printf '%s\n' $(declared_globals))
  offenders=""

  find "$ROOT_DIR/spells" -type f -not -path "*/.imps/*" -print | while IFS= read -r spell; do
    is_posix_shell_script "$spell" || continue
    while IFS= read -r line; do
      case $line in
        export\ *)
          name=${line#export }
          name=${name%%=*}
          printf '%s' "$allowed" | grep -qx "$name" || offenders="${offenders:+$offenders, }${spell#"$ROOT_DIR/"}:$name"
          ;;
      esac
    done < "$spell"
  done

  if [ -n "$offenders" ]; then
    TEST_FAILURE_REASON="undeclared globals exported: $offenders"
    return 1
  fi
  return 0
}

# Block ad-hoc global defaults outside declare-globals while allowing
# legacy cd cantrip state that mirrors historical behavior.
test_no_global_declarations_outside_declare_globals() {
  allowed_extra="WIZARDRY_CD_CANTRIP"
  declared=$(printf '%s\n' $(declared_globals))
  offenders=""

  find "$ROOT_DIR/spells" -type f -print | while IFS= read -r spell; do
    is_posix_shell_script "$spell" || continue
    case $spell in
      */.imps/declare-globals) continue ;;
    esac

    while IFS= read -r line; do
      case $line in
        :\ "\${[A-Z0-9_]*:=*" )
          name=$(printf '%s' "$line" | sed -n 's/^: "\${\([A-Z0-9_]*\):=.*/\1/p')
          [ -z "$name" ] && continue
          printf '%s\n' "$declared" "$allowed_extra" | grep -qx "$name" || offenders="${offenders:+$offenders, }${spell#"$ROOT_DIR/"}:$name"
          ;;
      esac
    done < "$spell"
  done

  if [ -n "$offenders" ]; then
    TEST_FAILURE_REASON="global defaults found outside declare-globals: $offenders"
    return 1
  fi
  return 0
}

# Ensure rc-style files do not squirrel away global state.
test_no_pseudo_globals_in_rc_files() {
  offenders=""
  find "$ROOT_DIR" -type f \( -name "*.rc" -o -name "*.rc.sh" \) -print | while IFS= read -r rcfile; do
    if grep -qE 'WIZARDRY_[A-Z0-9_]*=|SPELLBOOK_[A-Z0-9_]*=' "$rcfile" 2>/dev/null; then
      offenders="${offenders:+$offenders, }${rcfile#"$ROOT_DIR/"}"
    fi
  done

  if [ -n "$offenders" ]; then
    TEST_FAILURE_REASON="global-like settings stored in rc files: $offenders"
    return 1
  fi
  return 0
}

# --- Run all test cases ---

run_test_case "no duplicate spell names" test_no_duplicate_spell_names
run_test_case "menu spells require menu command" test_menu_spells_require_menu
run_test_case "spells have standard help handlers" test_spells_have_help_usage_handlers
run_test_case "warn about full paths to spells" test_warn_full_paths_to_spells
run_test_case "test files have matching spells" test_test_files_have_matching_spells
run_test_case "tests rely only on imps for helpers" test_tests_use_imps_for_helpers
run_test_case "scripts using declared globals have set -u" test_scripts_using_globals_have_set_u
run_test_case "declare-globals has exactly 3 globals" test_declare_globals_count
run_test_case "no undeclared globals exported" test_no_undeclared_global_exports
run_test_case "no global declarations outside declare-globals" test_no_global_declarations_outside_declare_globals
run_test_case "no pseudo-globals stored in rc files" test_no_pseudo_globals_in_rc_files

finish_tests
