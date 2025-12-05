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

# --- Check: Test files mirror spell structure ---
# Each test file should correspond to a spell
# This is a structural check - maintains test suite integrity

test_test_files_have_matching_spells() {
  orphan_tests=""
  
  find "$ROOT_DIR/.tests" -type f -name 'test-*.sh' -print | while IFS= read -r test_file; do
    # Skip special files
    case $test_file in
      */test-common.sh|*/test-install.sh|*/test-suite.sh|*/lib/*) continue ;;
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

# --- Check: Scripts using declared globals must have set -u enabled ---
# The declare-globals imp defines allowed global environment variables.
# Any script using these globals must have set -u enabled to ensure
# undefined variable access fails loudly.
# This is a behavioral check - enforces global variable policy

# Helper: Check if script actually uses a declared global (excluding heredocs and comments)
# This function filters out heredoc content and comments before checking for variable usage.
script_uses_declared_global() {
  spell=$1
  declared_globals=$2
  
  for global in $declared_globals; do
    # Use awk to filter the file before checking for variable usage:
    # - Skip lines inside single-quoted heredocs (<<'DELIM' ... DELIM)
    # - Skip comment lines (lines starting with optional whitespace then #)
    # - Print all other lines for grep to check
    # This prevents false positives from documentation mentioning variable names.
    if awk '
      # Detect start of single-quoted heredoc: matches <<'\''WORD'\''
      /<<'\''[A-Z]+'\''/ {
        in_heredoc=1
        heredoc_end=$0
        gsub(/.*<<'\''/, "", heredoc_end)
        gsub(/'\''.*/, "", heredoc_end)
        next
      }
      # Detect end of heredoc when line exactly matches the delimiter
      in_heredoc && $0 == heredoc_end { in_heredoc=0; next }
      # Skip all lines inside heredoc
      in_heredoc { next }
      # Skip comment lines
      /^[[:space:]]*#/ { next }
      # Print remaining lines for variable detection
      { print }
    ' "$spell" 2>/dev/null | grep -qE "\\\$$global([^A-Za-z_]|\$)|\\\${$global([^A-Za-z_}]|})"; then
      return 0
    fi
  done
  return 1
}

test_scripts_using_globals_have_set_u() {
  # List of globals declared in declare-globals
  declared_globals="WIZARDRY_DIR SPELLBOOK_DIR MUD_DIR"
  violations=""
  
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
    # Skip declare-globals itself
    case "$spell" in
      */.imps/declare-globals) continue ;;
    esac
    
    # Check if script uses any declared global (not in heredocs or comments)
    script_uses_declared_global "$spell" "$declared_globals" || continue
    
    # Script uses a declared global - verify it has set -u or set -eu
    # Pattern matches: set -u, set -eu, set -ue, set -euo, etc.
    # Allow leading whitespace for scripts that conditionally set strict mode
    if ! grep -qE '^[[:space:]]*set +-[euo]*u[euo]*' "$spell" 2>/dev/null; then
      rel_path=${spell#"$ROOT_DIR/spells/"}
      printf '%s\n' "$rel_path"
    fi
  done > "${WIZARDRY_TMPDIR}/global-violations.txt"
  
  violations=$(cat "${WIZARDRY_TMPDIR}/global-violations.txt" 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/, $//')
  rm -f "${WIZARDRY_TMPDIR}/global-violations.txt"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="scripts using declared globals without set -u: $violations"
    return 1
  fi
  return 0
}

# --- Check: No global declarations outside declare-globals ---
# Global declarations (using : "${VAR:=...}" syntax) should ONLY be in declare-globals.
# This prevents undeclared globals from sneaking in through alternate syntax.
test_no_global_declarations_outside_declare_globals() {
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
    # Skip declare-globals itself - that's where declarations belong
    case "$spell" in
      */.imps/declare-globals) continue ;;
    esac
    
    # Look for global declaration pattern: : "${VAR:=...}" or : "${VAR:=}"
    # This is the standard shell idiom for declaring globals with defaults
    if grep -qE '^[[:space:]]*: "\$\{[A-Z][A-Z0-9_]+:=' "$spell" 2>/dev/null; then
      rel_path=${spell#"$ROOT_DIR/spells/"}
      # Extract the variable names being declared
      vars=$(grep -oE '\$\{[A-Z][A-Z0-9_]+:=' "$spell" 2>/dev/null | sed 's/\${//;s/:=$//' | sort -u | tr '\n' ',' | sed 's/,$//')
      printf '%s (%s)\n' "$rel_path" "$vars"
    fi
  done > "${WIZARDRY_TMPDIR}/declaration-violations.txt"
  
  violations=$(cat "${WIZARDRY_TMPDIR}/declaration-violations.txt" 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/, $//')
  rm -f "${WIZARDRY_TMPDIR}/declaration-violations.txt"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="global declarations outside declare-globals: $violations"
    return 1
  fi
  return 0
}

# --- Check: declare-globals has exactly 3 globals ---
# Ensures no new globals are added without explicit tracking
test_declare_globals_count() {
  declare_globals_file="$ROOT_DIR/spells/.imps/declare-globals"
  
  if [ ! -f "$declare_globals_file" ]; then
    TEST_FAILURE_REASON="declare-globals file not found"
    return 1
  fi
  
  # Count global declarations using the standard shell idiom for declaring
  # variables with defaults. The pattern matches lines like:
  #   : "${WIZARDRY_DIR:=}"
  #   : "${SPELLBOOK_DIR:=}"
  # The colon-equals syntax (:=) assigns a default value if unset.
  global_count=$(grep -cE '^: "\$\{[A-Z][A-Z0-9_]+:=' "$declare_globals_file" 2>/dev/null || printf '0')
  
  if [ "$global_count" -ne 3 ]; then
    TEST_FAILURE_REASON="expected exactly 3 globals in declare-globals, found $global_count"
    return 1
  fi
  return 0
}

# --- Check: No undeclared globals exported ---
# Catches spells trying to create/export new globals that aren't in declare-globals.
# Allowed globals: WIZARDRY_DIR, SPELLBOOK_DIR, MUD_DIR
# Also allows common patterns that aren't really globals:
#   - PATH modifications
#   - Package manager variables (NIX_PACKAGE, APT_PACKAGE, etc.) used locally
#   - WIZARDRY_PLATFORM, WIZARDRY_RC_FILE, WIZARDRY_RC_FORMAT (rc detection vars)
test_no_undeclared_global_exports() {
  violations=""
  
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
    # Look for export statements with UPPERCASE variable names
    # Pattern: export VAR= or export VAR (without equals for pre-set vars)
    exports=$(grep -nE '^[[:space:]]*export[[:space:]]+[A-Z][A-Z0-9_]+=' "$spell" 2>/dev/null || true)
    
    if [ -n "$exports" ]; then
      # Check each export line
      printf '%s\n' "$exports" | while IFS= read -r line; do
        # Extract variable name
        var_name=$(printf '%s' "$line" | sed -E 's/.*export[[:space:]]+([A-Z][A-Z0-9_]+)=.*/\1/')
        
        # Skip allowed patterns
        case "$var_name" in
          PATH|NIX_PACKAGE|APT_PACKAGE|DNF_PACKAGE|YUM_PACKAGE|ZYPPER_PACKAGE|PACMAN_PACKAGE|APK_PACKAGE|PKGIN_PACKAGE)
            continue ;;
          WIZARDRY_DIR|SPELLBOOK_DIR|MUD_DIR)
            continue ;;  # Declared globals are allowed
          WIZARDRY_PLATFORM|WIZARDRY_RC_FILE|WIZARDRY_RC_FORMAT)
            continue ;;  # Used by learn-spell for rc file detection
        esac
        
        rel_path=${spell#"$ROOT_DIR/spells/"}
        printf '%s:%s\n' "$rel_path" "$var_name"
      done
    fi
  done > "${WIZARDRY_TMPDIR}/export-violations.txt"
  
  violations=$(cat "${WIZARDRY_TMPDIR}/export-violations.txt" 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/, $//')
  rm -f "${WIZARDRY_TMPDIR}/export-violations.txt"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="undeclared globals exported: $violations"
    return 1
  fi
  return 0
}

# --- Check: No pseudo-globals stored in rc files ---
# Bans the antipattern of persisting variables to shell rc files.
# Legitimate PATH modifications are allowed (handled by learn-spellbook).
# cd hook now uses a function instead of WIZARDRY_CD_CANTRIP variable.
test_no_pseudo_globals_in_rc_files() {
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
    # Skip legitimate PATH manipulation (learn-spellbook)
    case "$spell" in
      */learn-spellbook) continue ;;
    esac
    
    # Check for the specific antipattern: writing "export VAR=" to rc files
    # Pattern matches lines like: printf '...' "export VAR=" >> ~/.bashrc
    # or: echo "export VAR=" >> "$rc_file"
    # This catches scripts writing persistent variable exports to shell rc files.
    if grep -qE '^[^#]*\.(bashrc|zshrc|profile|rc)' "$spell" 2>/dev/null; then
      if grep -qE 'export[[:space:]]+[A-Z][A-Z0-9_]+=' "$spell" 2>/dev/null; then
        # Check if it writes something OTHER than PATH to rc files
        if grep -qE '(printf|echo).*export[[:space:]]+[^P]' "$spell" 2>/dev/null; then
          rel_path=${spell#"$ROOT_DIR/spells/"}
          printf '%s\n' "$rel_path"
        fi
      fi
    fi
  done > "${WIZARDRY_TMPDIR}/rc-pseudo-global-violations.txt"
  
  violations=$(cat "${WIZARDRY_TMPDIR}/rc-pseudo-global-violations.txt" 2>/dev/null | sort -u | head -10 | tr '\n' ', ' | sed 's/, $//')
  rm -f "${WIZARDRY_TMPDIR}/rc-pseudo-global-violations.txt"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="pseudo-globals stored in rc files: $violations"
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
run_test_case "scripts using declared globals have set -u" test_scripts_using_globals_have_set_u
run_test_case "declare-globals has exactly 3 globals" test_declare_globals_count
run_test_case "no undeclared globals exported" test_no_undeclared_global_exports
run_test_case "no global declarations outside declare-globals" test_no_global_declarations_outside_declare_globals
run_test_case "no pseudo-globals stored in rc files" test_no_pseudo_globals_in_rc_files

finish_tests
