#!/bin/sh
# Common structural and behavioral checks that apply across all spells and imps.
# Run first as part of test-magic to catch systemic issues early.
#
# This file contains cross-cutting tests that verify properties across the
# entire spellbook. Style/opinionated checks belong in vet-spell instead.
# Note: POSIX compliance (shebang, bashisms) is checked by verify-posix.
#
# Usage: common-tests.sh [SPELL_PATH...]
# If spell paths are provided, only tests those specific spells.
# Otherwise, tests all spells in the repository.

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Store filter mode and spell paths if provided
FILTER_MODE=0
FILTERED_SPELL_PATHS=""
if [ "$#" -gt 0 ]; then
  FILTER_MODE=1
  FILTERED_SPELL_PATHS="$*"
fi

# Helper: Check if a file is a POSIX shell script
is_posix_shell_script() {
  file=$1
  first_line=$(head -1 "$file" 2>/dev/null || true)
  case $first_line in
    '#!/bin/sh'|'#! /bin/sh') return 0 ;;
    *) return 1 ;;
  esac
}

# Helper: Check if a file is any shell script (including bash)
is_any_shell_script() {
  file=$1
  first_line=$(head -1 "$file" 2>/dev/null || true)
  case $first_line in
    '#!/bin/sh'|'#! /bin/sh') return 0 ;;
    '#!/bin/bash'|'#! /bin/bash') return 0 ;;
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

# ==============================================================================
# FILE LIST CACHING - Performance optimization
# Cache all spell files once instead of running find multiple times (11x faster)
# ==============================================================================

# Create cache file for spell list
SPELL_LIST_CACHE=$(mktemp "${WIZARDRY_TMPDIR}/spell-list-cache.XXXXXX")
trap 'rm -f "$SPELL_LIST_CACHE"' EXIT HUP INT TERM

# Build cached spell file list (run find once instead of 11+ times)
if [ "$FILTER_MODE" -eq 1 ]; then
  # Filter mode: only include specified spell paths
  for spell_path in $FILTERED_SPELL_PATHS; do
    # Convert to absolute path if relative
    case "$spell_path" in
      /*) abs_path="$spell_path" ;;
      *) 
        # Try with and without spells/ prefix
        if [ -f "$ROOT_DIR/$spell_path" ]; then
          abs_path="$ROOT_DIR/$spell_path"
        elif [ -f "$ROOT_DIR/spells/$spell_path" ]; then
          abs_path="$ROOT_DIR/spells/$spell_path"
        else
          abs_path="$spell_path"
        fi
        ;;
    esac
    
    # Add to cache if file exists and is executable
    if [ -f "$abs_path" ] && [ -x "$abs_path" ]; then
      printf '%s\n' "$abs_path" >> "$SPELL_LIST_CACHE"
    fi
  done
else
  # Normal mode: test all spells
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) \
    -print > "$SPELL_LIST_CACHE"
fi

# Helper: Iterate over cached spell list
for_each_spell() {
  callback=$1
  shift
  while IFS= read -r spell; do
    [ -n "$spell" ] || continue
    "$callback" "$spell" "$@"
  done < "$SPELL_LIST_CACHE"
}

# Helper: Iterate over cached spell list (POSIX scripts only)
for_each_posix_spell() {
  callback=$1
  shift
  while IFS= read -r spell; do
    [ -n "$spell" ] || continue
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    "$callback" "$spell" "$@"
  done < "$SPELL_LIST_CACHE"
}

# Helper: Iterate over cached spell list (any shell script)
for_each_any_shell_spell() {
  callback=$1
  shift
  while IFS= read -r spell; do
    [ -n "$spell" ] || continue
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_any_shell_script "$spell" || continue
    "$callback" "$spell" "$@"
  done < "$SPELL_LIST_CACHE"
}

# Helper: Iterate over cached spell list (POSIX scripts, excluding .imps)
for_each_posix_spell_no_imps() {
  callback=$1
  shift
  while IFS= read -r spell; do
    [ -n "$spell" ] || continue
    # Skip .imps
    case "$spell" in
      */.imps/*) continue ;;
    esac
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    "$callback" "$spell" "$@"
  done < "$SPELL_LIST_CACHE"
}

# ==============================================================================

# --- Check: No duplicate spell names ---
# All spells (including imps) must have unique names since they share PATH
# This is a structural check - prevents PATH conflicts

test_no_duplicate_spell_names() {
  # Collect all spell and imp names
  names_file=$(mktemp "${WIZARDRY_TMPDIR}/spell-names.XXXXXX")
  
  # Use cached file list instead of running find again
  collect_name() {
    spell=$1
    name=$(basename "$spell")
    printf '%s\n' "$name"
  }
  
  for_each_any_shell_spell collect_name | sort > "$names_file"
  
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
# Ensure each spell provides *_usage() and a --help|--usage|-h) case
test_spells_have_help_usage_handlers() {
  missing_usage=""
  missing_handler=""

  check_help_handler() {
    spell=$1
    rel_path=${spell#"$ROOT_DIR/spells/"}

    if ! grep -qE '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*_usage\(\)' "$spell" 2>/dev/null; then
      missing_usage="${missing_usage:+$missing_usage, }$rel_path"
      return
    fi

    if ! grep -qF -- '--help|--usage|-h)' "$spell" 2>/dev/null; then
      missing_handler="${missing_handler:+$missing_handler, }$rel_path"
    fi
  }
  
  for_each_posix_spell_no_imps check_help_handler

  if [ -n "$missing_usage" ]; then
    TEST_FAILURE_REASON="missing *_usage() function: $missing_usage"
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
  
  check_full_paths() {
    spell=$1
    # Skip bootstrap spells (install/core/), test-magic, and the spellbook menu.
    # Those scripts need repo-root paths to assemble PATH or locate user spells,
    # while normal spells should rely on PATH lookups.
    case $spell in
      */install/core/*|*/system/test-magic) return ;;
      */.imps/test/test-bootstrap|*/menu/spellbook) return ;;
    esac
    
    name=$(basename "$spell")
    
    # Check for patterns like $ROOT_DIR/spells/ or $ABS_DIR/spells/
    # excluding comments and variable definitions
    if grep -E '\$ROOT_DIR/spells/|\$ABS_DIR/spells/' "$spell" 2>/dev/null | \
       grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*[A-Z_]*=' | grep -q .; then
      printf '%s\n' "$name"
    fi
  }
  
  tmpfile="${WIZARDRY_TMPDIR}/full-paths.txt"
  : > "$tmpfile"  # Create empty file
  for_each_posix_spell check_full_paths > "$tmpfile"
  
  found_paths=$(cat "$tmpfile" 2>/dev/null | sort -u | tr '\n' ', ' | sed 's/,$//')
  rm -f "$tmpfile"
  
  if [ -n "$found_paths" ]; then
    printf 'WARNING: spells using full paths to invoke other spells (should use name only): %s\n' "$found_paths" >&2
  fi
  return 0
}

# --- Check: Test files mirror spell structure ---
# Each test file should correspond to a spell
# This is a structural check - maintains test suite integrity

test_test_files_have_matching_spells() {
  skip-if-compiled || return $?
  orphan_tests=""
  
  find "$ROOT_DIR/.tests" -type f -name 'test-*.sh' -o -name 'common-*.sh' -print | while IFS= read -r test_file; do
    # Skip special files
    case $test_file in
      */spells/.imps/test/test-bootstrap|*/test-install.sh|*/common-tests.sh) continue ;;
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
      test-*|common-*) ;;
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

# --- Check: Scripts using declared globals must have set -u enabled ---
# The declare-globals imp defines allowed global environment variables.
# Any script using these globals must have set -u enabled to ensure
# undefined variable access fails loudly.
# This is a behavioral check - enforces global variable policy

# Helper: Check if script actually uses a declared global UNSAFELY (excluding heredocs, comments, and safe ${VAR:-} patterns)
# This function filters out heredoc content, comments, and safe default patterns before checking for variable usage.
script_uses_declared_global() {
  spell=$1
  declared_globals=$2
  
  for global in $declared_globals; do
    # Use awk to filter the file before checking for variable usage:
    # - Skip lines inside single-quoted heredocs (<<'DELIM' ... DELIM)
    # - Skip comment lines (lines starting with optional whitespace then #)
    # - Skip lines that ONLY use the safe ${VAR:-default} or ${VAR-default} pattern
    # - Print all other lines for grep to check
    # This prevents false positives from documentation and safe usage patterns.
    if awk -v var="$global" '
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
    ' "$spell" 2>/dev/null | grep -E "\\\$$global([^A-Za-z_]|\$)|\\\${$global([^A-Za-z_}:-]|[}])" | grep -v '\${'"$global"':-' | grep -v '\${'"$global"'-' | grep -q .; then
      return 0
    fi
  done
  return 1
}

test_scripts_using_globals_have_set_u() {
  # List of globals declared in declare-globals
  declared_globals="WIZARDRY_DIR SPELLBOOK_DIR MUD_DIR"
  violations=""
  
  check_global_usage() {
    spell=$1
    # Skip declare-globals itself
    # Skip invoke-wizardry - it's sourced into user shell and can't set strict mode
    # Skip word-of-binding - it uses safe patterns (checks ${VAR-} before raw use)
    case "$spell" in
      */.imps/declare-globals|*/.imps/sys/invoke-wizardry|*/.imps/sys/word-of-binding) return ;;
    esac
    
    # Check if script uses any declared global (not in heredocs or comments)
    script_uses_declared_global "$spell" "$declared_globals" || return
    
    # Script uses a declared global - verify it has set -u or set -eu
    # Pattern matches: set -u, set -eu, set -ue, set -euo, etc.
    # Allow leading whitespace for scripts that conditionally set strict mode
    if ! grep -qE '^[[:space:]]*set +-[euo]*u[euo]*' "$spell" 2>/dev/null; then
      rel_path=${spell#"$ROOT_DIR/spells/"}
      printf '%s\n' "$rel_path"
    fi
  }
  
  tmpfile="${WIZARDRY_TMPDIR}/global-violations.txt"
  : > "$tmpfile"
  for_each_posix_spell check_global_usage > "$tmpfile"
  
  violations=$(cat "$tmpfile" 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/, $//')
  rm -f "$tmpfile"
  
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
  skip-if-compiled || return $?
  
  check_global_declarations() {
    spell=$1
    # Skip declare-globals itself - that's where declarations belong
    # Skip test-bootstrap - WIZARDRY_TMPDIR is a test-local temp directory,
    # not a persistent global exported to user scripts
    # Skip invoke-wizardry - it sets SPELLBOOK_DIR which is a declared global
    case "$spell" in
      */.imps/declare-globals|*/.imps/test/test-bootstrap|*/.imps/sys/invoke-wizardry) return ;;
    esac
    
    # Look for global declaration pattern: : "${VAR:=...}" or : "${VAR:=}"
    # This is the standard shell idiom for declaring globals with defaults
    if grep -qE '^[[:space:]]*: "\$\{[A-Z][A-Z0-9_]+:=' "$spell" 2>/dev/null; then
      rel_path=${spell#"$ROOT_DIR/spells/"}
      # Extract the variable names being declared
      vars=$(grep -oE '\$\{[A-Z][A-Z0-9_]+:=' "$spell" 2>/dev/null | sed 's/\${//;s/:=$//' | sort -u | tr '\n' ',' | sed 's/,$//')
      printf '%s (%s)\n' "$rel_path" "$vars"
    fi
  }
  
  tmpfile="${WIZARDRY_TMPDIR}/declaration-violations.txt"
  : > "$tmpfile"
  for_each_posix_spell check_global_declarations > "$tmpfile"
  
  violations=$(cat "$tmpfile" 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/, $//')
  rm -f "$tmpfile"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="global declarations outside declare-globals: $violations"
    return 1
  fi
  return 0
}

# --- Check: declare-globals has exactly 4 globals ---
# Ensures no new globals are added without explicit tracking
test_declare_globals_count() {
  skip-if-compiled || return $?
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
  global_count=$(grep -cE '^[[:space:]]*: "\$\{[A-Z][A-Z0-9_]+:=' "$declare_globals_file" 2>/dev/null || printf '0')
  
  if [ "$global_count" -ne 4 ]; then
    TEST_FAILURE_REASON="expected exactly 4 globals in declare-globals, found $global_count"
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
  
  check_undeclared_exports() {
    spell=$1
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
          PATH|NIX_PACKAGE|APT_PACKAGE|DNF_PACKAGE|YUM_PACKAGE|ZYPPER_PACKAGE|PACMAN_PACKAGE|APK_PACKAGE|PKGIN_PACKAGE|BREW_PACKAGE)
            return ;;
          WIZARDRY_DIR|SPELLBOOK_DIR|MUD_DIR|WIZARDRY_LOG_LEVEL)
            return ;;  # Declared globals are allowed
          WIZARDRY_PLATFORM|WIZARDRY_RC_FILE|WIZARDRY_RC_FORMAT)
            return ;;  # Used by learn-spell for rc file detection
          ASK_CANTRIP_INPUT)
            return ;;  # Used to pass stdin flag to ask-yn within same spell
        esac
        
        rel_path=${spell#"$ROOT_DIR/spells/"}
        printf '%s:%s\n' "$rel_path" "$var_name"
      done
    fi
  }
  
  tmpfile="${WIZARDRY_TMPDIR}/export-violations.txt"
  : > "$tmpfile"
  for_each_posix_spell check_undeclared_exports > "$tmpfile"
  
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
  check_rc_globals() {
    spell=$1
    # Skip legitimate PATH manipulation (learn-spellbook)
    case "$spell" in
      */learn-spellbook) return ;;
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
  }
  
  tmpfile="${WIZARDRY_TMPDIR}/rc-pseudo-global-violations.txt"
  : > "$tmpfile"
  for_each_posix_spell check_rc_globals > "$tmpfile"
  
  violations=$(cat "$tmpfile" 2>/dev/null | sort -u | head -10 | tr '\n' ', ' | sed 's/, $//')
  rm -f "$tmpfile"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="pseudo-globals stored in rc files: $violations"
    return 1
  fi
  return 0
}

# --- Check: Imps follow the one-function-or-zero rule ---
# Each imp must have either exactly one function with no executable code outside
# it (except comments/whitespace/shebang), OR zero functions.
# This ensures imps can be properly bound (sourced) or evoked (executed).
# Exemptions: test-bootstrap (complex test infrastructure)
test_imps_follow_function_rule() {
  skip-if-compiled || return $?
  violations=""
  
  find "$ROOT_DIR/spells/.imps" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r imp; do
    name=$(basename "$imp")
    should_skip_file "$name" && continue
    is_posix_shell_script "$imp" || continue
    
    # Count function definitions
    # Pattern matches: name() { or name () {
    func_count=$(grep -cE '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{' "$imp" 2>/dev/null) || func_count=0
    
    # If zero functions, that's valid
    if [ "$func_count" -eq 0 ]; then
      continue
    fi
    
    # If more than one function, that's a violation
    if [ "$func_count" -gt 1 ]; then
      rel_path=${imp#"$ROOT_DIR/spells/.imps/"}
      printf '%s (has %s functions)\n' "$rel_path" "$func_count"
      continue
    fi
    
    # If exactly one function, that's valid for binding
    # (We could add stricter checking for executable code outside the function later)
    
  done > "${WIZARDRY_TMPDIR}/imp-structure-violations.txt"
  
  violations=$(cat "${WIZARDRY_TMPDIR}/imp-structure-violations.txt" 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/, $//')
  rm -f "${WIZARDRY_TMPDIR}/imp-structure-violations.txt"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="imps violating function rule: $violations"
    return 1
  fi
  return 0
}

# --- Check: Imps have 1-3 lines of opening comments ---
# Each imp should have descriptive opening comments serving as its spec.
# The comments should be right after the shebang (line 2 starts with #).
test_imps_have_opening_comments() {
  violations=""
  
  find "$ROOT_DIR/spells/.imps" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r imp; do
    name=$(basename "$imp")
    should_skip_file "$name" && continue
    is_posix_shell_script "$imp" || continue
    
    # Count consecutive comment lines starting from line 2
    comment_count=0
    line_num=0
    while IFS= read -r line; do
      line_num=$((line_num + 1))
      [ "$line_num" -eq 1 ] && continue  # Skip shebang
      
      case "$line" in
        '#'*)
          comment_count=$((comment_count + 1))
          if [ "$comment_count" -ge 3 ]; then
            break
          fi
          ;;
        '')
          # Allow blank line after comments
          break
          ;;
        *)
          # Non-comment, non-blank line
          break
          ;;
      esac
    done < "$imp"
    
    if [ "$comment_count" -lt 1 ] || [ "$comment_count" -gt 3 ]; then
      rel_path=${imp#"$ROOT_DIR/spells/.imps/"}
      printf '%s (has %s comment lines)\n' "$rel_path" "$comment_count"
    fi
  done > "${WIZARDRY_TMPDIR}/imp-comment-violations.txt"
  
  violations=$(cat "${WIZARDRY_TMPDIR}/imp-comment-violations.txt" 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/, $//')
  rm -f "${WIZARDRY_TMPDIR}/imp-comment-violations.txt"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="imps with invalid comment count: $violations"
    return 1
  fi
  return 0
}

# --- Check: Bootstrap spells have "Bootstrap spell" in opening comment ---
# Canonical list of bootstrap spells (hardcoded):
# - install (root installer)
# - detect-distro (platform detection)
# - All spells in spells/.arcana/core/
# These spells must have "Bootstrap spell" in their opening comment (first few lines after shebang).
test_bootstrap_spells_identified() {
  skip-if-compiled || return $?
  # Canonical list of bootstrap spell paths (relative to ROOT_DIR)
  # This list is the authoritative source for what constitutes a bootstrap spell
  bootstrap_paths="
install
spells/divination/detect-distro
spells/.arcana/core/
"
  
  violations=""
  
  for path in $bootstrap_paths; do
    # Handle directory (spells/.arcana/core/) vs single file
    case "$path" in
      */)
        # It's a directory - check all executable files in it
        dir="$ROOT_DIR/$path"
        if [ -d "$dir" ]; then
          for file in "$dir"*; do
            [ -f "$file" ] || continue
            [ -x "$file" ] || continue
            name=$(basename "$file")
            should_skip_file "$name" && continue
            is_posix_shell_script "$file" || continue
            
            # Check if "Bootstrap spell" appears in first 5 lines
            if ! head -5 "$file" | grep -qi "bootstrap spell"; then
              rel_path=${file#"$ROOT_DIR/"}
              violations="$violations $rel_path"
            fi
          done
        fi
        ;;
      *)
        # It's a single file
        file="$ROOT_DIR/$path"
        if [ -f "$file" ] && [ -x "$file" ]; then
          is_posix_shell_script "$file" || continue
          
          # Check if "Bootstrap spell" appears in first 5 lines
          if ! head -5 "$file" | grep -qi "bootstrap spell"; then
            violations="$violations $path"
          fi
        fi
        ;;
    esac
  done
  
  violations=$(printf '%s' "$violations" | sed 's/^ //' | tr ' ' ', ')
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="bootstrap spells missing 'Bootstrap spell' comment: $violations"
    return 1
  fi
  return 0
}

# --- Check: Spells follow function discipline ---
# Each spell may have *_usage() plus at most a few additional functions.
# The rule enforces linear, readable scrolls over proto-libraries.
# - 0-1 additional functions: freely allowed (the "spell-heart helper")
# - 2 additional functions: warning (invoked from multiple paths, not suitable as imp)
# - 3 additional functions: warning (marginal case)
# - 4+ additional functions: error (proto-library, needs decomposition)
test_spells_follow_function_discipline() {
  skip-if-compiled || return $?
  tmpfile_2=$(mktemp "${WIZARDRY_TMPDIR}/func-warn-2.XXXXXX")
  tmpfile_3=$(mktemp "${WIZARDRY_TMPDIR}/func-warn-3.XXXXXX")
  tmpfile_4plus=$(mktemp "${WIZARDRY_TMPDIR}/func-viol-4plus.XXXXXX")
  
  # Hardcoded exceptions for complex interactive systems requiring architectural decisions
  # These spells are large (500-1200 lines) with genuinely multi-use helper functions
  # and complex state management that justifies preserving helper functions.
  # Documented in EXEMPTIONS.md as requiring careful decomposition analysis.
  # Bootstrap scripts (system/banish) require inline helpers since wizardry isn't installed yet.
  exempted_spells="
spellcraft/lint-magic
menu/spellbook
cantrips/menu
.arcana/mud/cd
.arcana/core/install-core
.arcana/lightning/install-lightning
.arcana/lightning/lightning-menu
.arcana/node/node-menu
divination/identify-room
system/update-all
system/test-magic
system/banish
"
  
  check_function_discipline() {
    spell=$1
    name=$(basename "$spell")
    rel_path=${spell#"$ROOT_DIR/spells/"}
    
    # Skip exempted spells
    is_exempted=0
    for exempted in $exempted_spells; do
      if [ "$rel_path" = "$exempted" ]; then
        is_exempted=1
        break
      fi
    done
    [ "$is_exempted" -eq 1 ] && return
    
    # Count all function definitions
    # Note: This simple pattern-based approach may count functions in comments
    # or heredocs, but this is acceptable for a stylistic check that identifies
    # proto-libraries. False positives would be rare in practice.
    # Pattern 1: func() { on same line
    func_count_inline=$(grep -cE '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{' "$spell" 2>/dev/null || true)
    func_count_inline=${func_count_inline:-0}
    # Pattern 2: func() on one line, { on next line
    func_count_multiline=$(grep -cE '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*$' "$spell" 2>/dev/null || true)
    func_count_multiline=${func_count_multiline:-0}
    func_count=$((func_count_inline + func_count_multiline))
    
    # Subtract 2 for standard functions: *_usage and the wrapper function (incantation)
    # Every spell now has both a *_usage function and a wrapper function matching its name
    # Additional functions beyond these two are considered helper functions
    additional_funcs=$((func_count - 2))
    
    # Allow negative (missing functions are caught by other tests)
    [ "$additional_funcs" -lt 0 ] && additional_funcs=0
    
    # Write to appropriate temp file based on additional function count
    if [ "$additional_funcs" -ge 4 ]; then
      printf '%s(%s)\n' "$rel_path" "$additional_funcs" >> "$tmpfile_4plus"
    elif [ "$additional_funcs" -eq 3 ]; then
      printf '%s(%s)\n' "$rel_path" "$additional_funcs" >> "$tmpfile_3"
    elif [ "$additional_funcs" -eq 2 ]; then
      printf '%s(%s)\n' "$rel_path" "$additional_funcs" >> "$tmpfile_2"
    fi
  }
  
  for_each_posix_spell_no_imps check_function_discipline
  
  # Read and format results
  warnings_2=$(head -20 "$tmpfile_2" 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
  warnings_3=$(head -20 "$tmpfile_3" 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
  violations_4plus=$(head -20 "$tmpfile_4plus" 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
  
  rm -f "$tmpfile_2" "$tmpfile_3" "$tmpfile_4plus"
  
  # Print warnings (non-fatal)
  if [ -n "$warnings_2" ]; then
    printf 'WARNING: spells with 2 additional functions (consider refactoring): %s\n' "$warnings_2" >&2
  fi
  if [ -n "$warnings_3" ]; then
    printf 'WARNING: spells with 3 additional functions (strongly consider refactoring): %s\n' "$warnings_3" >&2
  fi
  
  # Fail on 4+ additional functions
  if [ -n "$violations_4plus" ]; then
    TEST_FAILURE_REASON="spells with 4+ additional functions (proto-libraries, must decompose): $violations_4plus"
    return 1
  fi
  
  return 0
}

# --- Check: No function name collisions ---
# When spells are sourced via invoke-wizardry, function names must be unique
# This prevents one spell from overwriting another's functions
# This is a structural check - ensures spell isolation when sourced
#
# EXCEPTION: Compiled spells (doppelganger) are standalone executables that inline
# their dependencies. Multiple compiled spells will naturally have duplicate function
# definitions from shared imps (e.g., _has, _there). This is expected and acceptable
# since compiled spells never source each other - they are independent executables.

test_no_function_name_collisions() {
  # Skip collision check for compiled/doppelganger spells - duplicates are expected
  # when imps are inlined into multiple standalone executables
  if [ "${WIZARDRY_TEST_COMPILED:-0}" = "1" ]; then
    return 0
  fi
  
  # Track all function definitions
  collisions_file=$(mktemp "${WIZARDRY_TMPDIR}/func-collisions.XXXXXX")
  functions_file=$(mktemp "${WIZARDRY_TMPDIR}/func-list.XXXXXX")
  imp_functions_file=$(mktemp "${WIZARDRY_TMPDIR}/imp-funcs.XXXXXX")
  
  # Check all executable spells (excluding .imps and .arcana)
  for spell_dir in "$ROOT_DIR"/spells/*; do
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
          printf '%s:%s\n' "$func_name" "$spell" >> "$functions_file"
        fi
      done < "$spell"
    done
  done
  
  # Check imps for underscore-prefixed functions (track separately)
  for imp_family in "$ROOT_DIR"/spells/.imps/*; do
    [ -d "$imp_family" ] || continue
    for imp in "$imp_family"/*; do
      [ -f "$imp" ] && [ -x "$imp" ] || continue
      
      while IFS= read -r line; do
        if printf '%s' "$line" | grep -qE '^_[a-zA-Z_][a-zA-Z0-9_]*\(\)[[:space:]]*\{'; then
          func_name=$(printf '%s' "$line" | sed 's/()[[:space:]]*{.*//')
          printf '%s:%s\n' "$func_name" "$imp" >> "$imp_functions_file"
        fi
      done < "$imp"
    done
  done
  
  # Find collisions in spells (non-.imps files)
  if [ -f "$functions_file" ]; then
    sort "$functions_file" | awk -F: '
    {
      if (seen[$1]) {
        if (!reported[$1]) {
          print "Function " $1 " collision: " seen[$1] " and " $2
          reported[$1] = 1
        }
      } else {
        seen[$1] = $2
      }
    }' > "$collisions_file"
  fi
  
  # Find collisions within imps themselves (underscore functions colliding with other imps)
  if [ -f "$imp_functions_file" ]; then
    sort "$imp_functions_file" | awk -F: '
    {
      if (seen[$1]) {
        if (!reported[$1]) {
          print "Function " $1 " collision: " seen[$1] " and " $2
          reported[$1] = 1
        }
      } else {
        seen[$1] = $2
      }
    }' >> "$collisions_file"
  fi
  
  collisions=$(cat "$collisions_file" 2>/dev/null || true)
  rm -f "$collisions_file" "$functions_file" "$imp_functions_file"
  
  if [ -n "$collisions" ]; then
    TEST_FAILURE_REASON="function name collisions detected: $(printf '%s' "$collisions" | tr '\n' '; ')"
    return 1
  fi
  return 0
}

# --- Check: Spells and imps have true name functions ---
# All spells and imps should have a true name function that matches the filename
# For imps: _underscore_name (e.g., clip-copy -> _clip_copy)
# For spells: snake_case name (e.g., lint-magic -> lint_magic)
# This enables word-of-binding to source and call them efficiently
# This is a NON-FAILING check - warnings only for visibility

test_spells_have_true_name_functions() {
  warnings=""
  
  check_true_names() {
    spell=$1
    name=$(basename "$spell")
    
    # Determine if this is an imp
    is_imp=0
    case $spell in
      */.imps/*) is_imp=1 ;;
    esac
    
    # Convert filename to expected true name
    # For hyphenated names: clip-copy -> clip_copy
    true_name=$(printf '%s' "$name" | sed 's/-/_/g')
    
    # For imps, add underscore prefix
    if [ "$is_imp" -eq 1 ]; then
      true_name="_$true_name"
    fi
    
    # Check if the true name function exists
    if ! grep -qE "^[[:space:]]*${true_name}[[:space:]]*\(\)" "$spell" 2>/dev/null; then
      rel_path=${spell#"$ROOT_DIR/spells/"}
      printf '%s (missing %s)\n' "$rel_path" "$true_name"
    fi
  }
  
  tmpfile="${WIZARDRY_TMPDIR}/missing-true-names.txt"
  : > "$tmpfile"
  for_each_posix_spell check_true_names > "$tmpfile"
  
  warnings=$(cat "$tmpfile" 2>/dev/null | head -20 | tr '\n' ', ' | sed 's/, $//')
  rm -f "$tmpfile"
  
  # This is a non-failing check - just print warnings
  if [ -n "$warnings" ]; then
    printf 'INFO: spells/imps without true name functions (consider adding for word-of-binding): %s\n' "$warnings" >&2
  fi
  
  # Always return success (non-failing check)
  return 0
}

# --- Check: All spells MUST have wrapper functions (FAILING TEST) ---
# All spells must have a wrapper function matching their filename for word-of-binding.
# For spells: snake_case name (e.g., lint-magic -> lint_magic)
# This enables sourcing spells into the shell for efficient invocation.
# Unlike test_spells_have_true_name_functions, this is a FAILING test.
#
# Exemptions must be documented in .github/EXEMPTIONS.md with justification.

test_spells_require_wrapper_functions() {
  skip-if-compiled || return $?
  violations=""
  
  # Check all executable spell files (not imps)
  find "$ROOT_DIR/spells" -type f -not -path "*/.imps/*" -not -path "*/.arcana/*" \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
    rel_path=${spell#"$ROOT_DIR/spells/"}
    
    # Skip spells that are meant to be sourced (not executed)
    # These spells set environment variables and must run in the current shell
    case "$rel_path" in
      cantrips/colors) continue ;;
    esac
    
    # Convert filename to expected wrapper function name
    # For hyphenated names: lint-magic -> lint_magic
    wrapper_name=$(printf '%s' "$name" | sed 's/-/_/g')
    
    # Check if the wrapper function exists
    if ! grep -qE "^[[:space:]]*${wrapper_name}[[:space:]]*\(\)" "$spell" 2>/dev/null; then
      printf '%s (missing %s)\n' "$rel_path" "$wrapper_name"
    fi
  done > "${WIZARDRY_TMPDIR}/missing-wrappers.txt"
  
  violations=$(cat "${WIZARDRY_TMPDIR}/missing-wrappers.txt" 2>/dev/null | head -30 | tr '\n' ', ' | sed 's/, $//')
  rm -f "${WIZARDRY_TMPDIR}/missing-wrappers.txt"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="spells missing wrapper functions (required for word-of-binding): $violations"
    return 1
  fi
  return 0
}

# --- Check: Spells have no more than 3 --flag arguments ---
# Spells should use minimal flags (0-1 freely, 2 with warning, 3 with warning, 4+ fails)
# This enforces simplicity and discourages complex option parsing
# This is a behavioral check - warnings at 2-3 flags, fails at 4+ flags

test_spells_have_limited_flags() {
  # Skip for compiled/doppelganger spells - inlined imps may add flags
  if [ "${WIZARDRY_TEST_COMPILED:-0}" = "1" ]; then
    return 0
  fi
  
  tmpfile_2=$(mktemp "${WIZARDRY_TMPDIR}/flag-warn-2.XXXXXX")
  tmpfile_3=$(mktemp "${WIZARDRY_TMPDIR}/flag-warn-3.XXXXXX")
  tmpfile_4plus=$(mktemp "${WIZARDRY_TMPDIR}/flag-viol-4plus.XXXXXX")
  
  check_flags() {
    spell=$1
    name=$(basename "$spell")
    rel_path=${spell#"$ROOT_DIR/spells/"}
    
    # Count distinct flag options by looking at both case and if patterns
    # Exclude standard --help|--usage|-h, catch-all -*, -- (end of options), and --- (dividers)
    flag_count=$(awk '
      BEGIN { seen_flags = "" }
      
      # Track if we are in argument parsing section (case or while loop)
      /while.*\$.*-gt 0/ { in_args = 1 }
      /case.*\$\{?1/ { in_args = 1 }
      in_args && /^[[:space:]]*esac[[:space:]]*$/ && parsing_done == 0 { 
        parsing_done = 1
        in_args = 0
      }
      
      # When in argument parsing, capture flag patterns from case statements
      in_args && /^[[:space:]]+(-[a-zA-Z]|--[a-zA-Z-]+)(\||[[:space:]]*\))/ {
        line = $0
        # Skip help flags
        if (line ~ /--help|--usage|-h\)/) next
        # Skip catch-all pattern
        if (line ~ /^[[:space:]]+-\*\)/) next
        # Skip -- (end of options marker)
        if (line ~ /^[[:space:]]+--\)/) next
        # Skip --- (divider marker)
        if (line ~ /^[[:space:]]+---\)/) next
        
        # Extract flag name
        match(line, /(--[a-zA-Z-]+|-[a-zA-Z])/, flag)
        if (flag[0] && index(seen_flags, flag[0]) == 0) {
          seen_flags = seen_flags " " flag[0]
          print flag[0]
        }
      }
      
      # Also check for if-based flag handling: if [ "$1" = "--flag" ]
      /if[[:space:]]*\[[[:space:]]*["\$]*\{?1/ && /(=|==)[[:space:]]*["'\''](--[a-zA-Z-]+|-[a-zA-Z])["'\'']/ {
        line = $0
        # Skip help flags
        if (line ~ /--help|--usage|-h/) next
        # Skip --- dividers
        if (line ~ /---/) next
        
        # Extract flag name
        match(line, /(--[a-zA-Z-]+|-[a-zA-Z])/, flag)
        if (flag[0] && index(seen_flags, flag[0]) == 0) {
          seen_flags = seen_flags " " flag[0]
          print flag[0]
        }
      }
    ' "$spell" 2>/dev/null | wc -l)
    
    flag_count=${flag_count:-0}
    
    # Write to appropriate temp file based on flag count
    if [ "$flag_count" -ge 4 ]; then
      printf '%s(%s)\n' "$rel_path" "$flag_count" >> "$tmpfile_4plus"
    elif [ "$flag_count" -eq 3 ]; then
      printf '%s(%s)\n' "$rel_path" "$flag_count" >> "$tmpfile_3"
    elif [ "$flag_count" -eq 2 ]; then
      printf '%s(%s)\n' "$rel_path" "$flag_count" >> "$tmpfile_2"
    fi
  }
  
  for_each_posix_spell check_flags
  
  # Read and format results
  warnings_2=$(head -20 "$tmpfile_2" 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
  warnings_3=$(head -20 "$tmpfile_3" 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
  violations_4plus=$(head -20 "$tmpfile_4plus" 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
  
  rm -f "$tmpfile_2" "$tmpfile_3" "$tmpfile_4plus"
  
  # Print warnings (non-fatal)
  if [ -n "$warnings_2" ]; then
    printf 'WARNING: spells with 2 flags (consider simplifying): %s\n' "$warnings_2" >&2
  fi
  
  if [ -n "$warnings_3" ]; then
    printf 'WARNING: spells with 3 flags (strongly consider simplifying): %s\n' "$warnings_3" >&2
  fi
  
  # Fail on 4+ flags
  if [ -n "$violations_4plus" ]; then
    TEST_FAILURE_REASON="spells with 4+ flags (exceeds limit, must simplify): $violations_4plus"
    return 1
  fi
  
  return 0
}

# --- Check: Spells have no more than 3 positional arguments ---
# Spells should use minimal positional arguments (0-1 freely, 2 with warning, 3 with warning, 4+ fails)
# This enforces simplicity and discourages complex interfaces
# This is a behavioral check - warnings at 2-3 args, fails at 4+ args

test_spells_have_limited_positional_args() {
  # Skip for compiled/doppelganger spells - inlined imps may change usage patterns
  if [ "${WIZARDRY_TEST_COMPILED:-0}" = "1" ]; then
    return 0
  fi
  
  tmpfile_2=$(mktemp "${WIZARDRY_TMPDIR}/posarg-warn-2.XXXXXX")
  tmpfile_3=$(mktemp "${WIZARDRY_TMPDIR}/posarg-warn-3.XXXXXX")
  tmpfile_4plus=$(mktemp "${WIZARDRY_TMPDIR}/posarg-viol-4plus.XXXXXX")
  
  check_positional_args() {
    spell=$1
    name=$(basename "$spell")
    rel_path=${spell#"$ROOT_DIR/spells/"}
    
    # Extract Usage line from the spell (from usage function or direct)
    usage=$(awk '
      # Look for usage function
      /^[a-zA-Z_][a-zA-Z0-9_]*_usage\(\)/ { in_usage = 1; next }
      # Or direct Usage: line
      /^Usage:/ { in_usage = 1; capture = 1 }
      # Capture Usage lines
      in_usage && /^Usage:/ { capture = 1 }
      in_usage && capture { 
        print
        # Stop at blank line or end of heredoc
        if (/^[[:space:]]*$/ || /^USAGE/ || /^[A-Z][A-Z_]+$/) exit
      }
      in_usage && /^}/ { exit }
    ' "$spell" 2>/dev/null | head -3)
    
    if [ -z "$usage" ]; then
      return
    fi
    
    # Count positional arguments from Usage line
    # Look for <arg> patterns or UPPERCASE_ARGS (but not in [...] optional sections)
    # Exclude variadic arguments like "..." or FILE... or [FILES...]
    arg_count=$(printf '%s\n' "$usage" | \
      # Remove optional flag sections in [...]
      sed 's/\[[^]]*\]//g' | \
      # Extract positional argument patterns
      grep -oE '<[A-Za-z_-]+>|[A-Z][A-Z0-9_-]+' | \
      # Exclude variadic patterns
      grep -v '\.\.\.' | \
      # Count unique arguments
      sort -u | wc -l)
    
    arg_count=${arg_count:-0}
    
    # Write to appropriate temp file based on argument count
    if [ "$arg_count" -ge 4 ]; then
      printf '%s(%s)\n' "$rel_path" "$arg_count" >> "$tmpfile_4plus"
    elif [ "$arg_count" -eq 3 ]; then
      printf '%s(%s)\n' "$rel_path" "$arg_count" >> "$tmpfile_3"
    elif [ "$arg_count" -eq 2 ]; then
      printf '%s(%s)\n' "$rel_path" "$arg_count" >> "$tmpfile_2"
    fi
  }
  
  for_each_posix_spell check_positional_args
  
  # Read and format results
  warnings_2=$(head -20 "$tmpfile_2" 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
  warnings_3=$(head -20 "$tmpfile_3" 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
  violations_4plus=$(head -20 "$tmpfile_4plus" 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
  
  rm -f "$tmpfile_2" "$tmpfile_3" "$tmpfile_4plus"
  
  # Print warnings (non-fatal)
  if [ -n "$warnings_2" ]; then
    printf 'WARNING: spells with 2 positional arguments (consider simplifying): %s\n' "$warnings_2" >&2
  fi
  
  if [ -n "$warnings_3" ]; then
    printf 'WARNING: spells with 3 positional arguments (strongly consider simplifying): %s\n' "$warnings_3" >&2
  fi
  
  # Fail on 4+ positional arguments
  if [ -n "$violations_4plus" ]; then
    TEST_FAILURE_REASON="spells with 4+ positional arguments (exceeds limit, must simplify): $violations_4plus"
    return 1
  fi
  
  return 0
}

# --- Check: No all-caps variable assignments (env var antipattern) ---
# All local variables should use lowercase. ALL_CAPS conventionally indicates
# environment variables and using it for local vars creates confusion.
# Only documented exceptions in EXEMPTIONS.md are allowed.

test_no_allcaps_variable_assignments() {
  violations=""
  
  check_allcaps() {
    spell=$1
    name=$(basename "$spell")
    rel_path=${spell#"$ROOT_DIR/spells/"}
    
    # Skip exempt files
    case "$rel_path" in
      # cantrips/colors defines color variables (documented exception)
      cantrips/colors) return ;;
      # Test infrastructure exempt
      .imps/test/*) return ;;
      # Output/logging imps exempt (they set WIZARDRY_* flags)
      .imps/out/*) return ;;
      # Bootstrap/arcana scripts have different rules  
      .arcana/*) return ;;
    esac
    
    # Look for ALL_CAPS variable assignments
    # Match: VAR= or VAR=$... or VAR=$(...) but not export statements (those are checked elsewhere)
    allcaps_vars=$(grep -nE '^[[:space:]]*[A-Z][A-Z_0-9]*=' "$spell" 2>/dev/null | \
      grep -v -E '(export|PATH=|HOME=|IFS=|CDPATH=|TMPDIR=|USER=|SHELL=|TERM=|LANG=)' | \
      grep -v -E '(NIX_PACKAGE|APT_PACKAGE|DNF_PACKAGE|YUM_PACKAGE|ZYPPER_PACKAGE|PACMAN_PACKAGE|APK_PACKAGE|PKGIN_PACKAGE|BREW_PACKAGE)' | \
      grep -v -E '(WIZARDRY_|SPELLBOOK_DIR|MUD_DIR|TEST_|REAL_SUDO_BIN|ASSUME_YES|FORCE_INSTALL|ROOT_DIR|DISTRO)' | \
      grep -v -E '(AWAIT_KEYPRESS_KEEP_RAW|BWRAP_|SANDBOX_|MACOS_)' | \
      grep -v -E '(ASK_CANTRIP_INPUT|SELECT_INPUT_MODE|MENU_LOOP_LIMIT|REQUIRE_COMMAND|MENU_LOG)' | \
      grep -v -E '(RESET|BOLD|ITALICS|UNDERLINED|BLINK|INVERT|STRIKE|ESC)' | \
      grep -v -E '(RED|GREEN|BLUE|YELLOW|CYAN|WHITE|BLACK|PURPLE|GRE[YA]|LIGHT_)' | \
      grep -v -E '(BRIGHT_|BG_|THEME_)' | \
      grep -v -E '(KEY=value)' | \
      grep -v -E 'logging-example|spell-name' | \
      head -5)
    
    if [ -n "$allcaps_vars" ]; then
      # Format: filename:linenum:content
      formatted=$(printf '%s\n' "$allcaps_vars" | sed "s|^|$rel_path:|" | tr '\n' '; ' | sed 's/; $//')
      printf '%s\n' "$formatted"
    fi
  }
  
  tmpfile="${WIZARDRY_TMPDIR}/allcaps-violations.txt"
  : > "$tmpfile"
  for_each_posix_spell check_allcaps > "$tmpfile"
  
  violations=$(cat "$tmpfile" 2>/dev/null | head -20)
  rm -f "$tmpfile"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="ALL_CAPS variable assignments found (use lowercase for local vars): $violations"
    return 1
  fi
  
  return 0
}

# --- Check: Scripts have explicit error handling mode early ---
# All spells and action imps must have "set -eu" or "set +eu" early in the file (within first 50 lines).
# Use "set -eu" for strict mode (most spells) or "set +eu" for permissive mode (sourceable scripts).
# Allowed before set: shebang, opening comment, help handler.

test_scripts_have_set_eu_early() {
  violations=""
  
  check_set_eu() {
    spell=$1
    name=$(basename "$spell")
    rel_path=${spell#"$ROOT_DIR/spells/"}
    
    # Skip exempt files (bootstrap/special cases only)
    case "$rel_path" in
      # Bootstrap/arcana scripts exempt (different rules)
      .arcana/*) return ;;
      # install script exempt (bootstrap, has special PATH setup)
      install) return ;;
      # Test bootstrap exempt (sets up test environment)
      .imps/test/test-bootstrap) return ;;
      # Conditional imps exempt (return exit codes, not errors)
      .imps/cond/*|.imps/lex/*|.imps/menu/*) return ;;
      # Bootstrap spells that have long argument parsing before set
      divination/detect-rc-file|system/test-magic) return ;;
    esac
    
    # In compiled mode, wrapper functions are unwrapped so set may appear later
    # Just check that set -eu or set +eu exists somewhere in the file
    if [ "${WIZARDRY_TEST_COMPILED:-0}" = "1" ]; then
      if ! grep -qE '^[[:space:]]*set [+-][euo]*[eu][euo]*' "$spell"; then
        printf '%s\n' "$rel_path"
      fi
      return
    fi
    
    # Auto-detect word-of-binding pattern:
    # 1. Has wrapper function matching filename (with underscores for hyphens)
    #    OR has true name function for imps (underscore prefix)
    # 2. Has self-execute pattern: case "$0" in */name) wrapper "$@" ;; esac
    # If both present, spell uses word-of-binding and set can be inside wrapper
    
    # Convert filename to function name (hyphens to underscores)
    func_name=$(printf '%s' "$name" | tr '-' '_')
    true_name="_${func_name}"  # For imps
    
    # Check for wrapper function definition (spell pattern) or true name function (imp pattern)
    has_wrapper=0
    if grep -qE "^[[:space:]]*${func_name}[[:space:]]*\(\)" "$spell" 2>/dev/null || \
       grep -qE "^[[:space:]]*${true_name}[[:space:]]*\(\)" "$spell" 2>/dev/null; then
      has_wrapper=1
    fi
    
    # Check for self-execute pattern
    has_self_execute=0
    if grep -qE 'case[[:space:]]+"\$0"[[:space:]]+in' "$spell" 2>/dev/null && \
       grep -qE "\*/${name}\)" "$spell" 2>/dev/null; then
      has_self_execute=1
    fi
    
    # If word-of-binding pattern detected, check for set -eu or set +eu anywhere
    if [ "$has_wrapper" = "1" ] && [ "$has_self_execute" = "1" ]; then
      # Word-of-binding spell: set -eu or set +eu should exist somewhere (inside or outside wrapper)
      if ! grep -qE '^[[:space:]]*set [+-][euo]*[eu][euo]*' "$spell"; then
        printf '%s\n' "$rel_path"
      fi
    else
      # Regular spell: check if set -eu or set +eu appears in first 50 lines
      # Pattern matches: set -eu, set -ue, set -euo, set +eu, set +ue, etc.
      if ! head -50 "$spell" | grep -qE '^[[:space:]]*set [+-][euo]*[eu][euo]*'; then
        printf '%s\n' "$rel_path"
      fi
    fi
  }
  
  tmpfile="${WIZARDRY_TMPDIR}/missing-set-eu.txt"
  : > "$tmpfile"
  for_each_posix_spell check_set_eu > "$tmpfile"
  
  violations=$(cat "$tmpfile" 2>/dev/null | head -20 | tr '\n' ', ' | sed 's/, $//')
  rm -f "$tmpfile"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="scripts missing explicit error handling mode: $violations (add 'set -eu' or 'set +eu' after opening comment, within first 50 lines)"
    return 1
  fi
  
  return 0
}

# --- Check: Spells source env-clear immediately after set -eu ---
# All spells must source env-clear on the line immediately after set -eu (or within 2 lines).
# This prevents environment variable antipattern from returning.
# Imps are exempt as they're helpers, not top-level entry points.

test_spells_source_env_clear_after_set_eu() {
  # Skip in compiled mode - compiled spells don't need env-clear (they're standalone)
  skip-if-compiled || return $?
  
  violations=""
  
  check_env_clear_placement() {
    spell=$1
    name=$(basename "$spell")
    rel_path=${spell#"$ROOT_DIR/spells/"}
    
    # Skip exempt files
    case "$rel_path" in
      # Imps exempt (they're helpers, not top-level spells)
      .imps/*) return ;;
      # Bootstrap/arcana scripts exempt (run before wizardry infrastructure available)
      .arcana/*) return ;;
      # install script exempt (bootstrap)
      install) return ;;
      # Bootstrap spells used by install (must be standalone)
      divination/detect-rc-file|cantrips/ask-yn|cantrips/memorize|cantrips/require-wizardry|spellcraft/learn) return ;;
      # Bootstrap scripts with conditional env-clear sourcing (run before wizardry fully installed)
      system/banish|spellcraft/compile-spell|spellcraft/doppelganger) return ;;
      # Scripts that need PATH setup before env-clear to find it
      system/test-magic|system/test-spell|system/verify-posix|spellcraft/lint-magic|enchant/enchant) return ;;
      # Spells using wrapper function pattern (set -eu inside function for sourceable spells)
      priorities/get-priority|priorities/prioritize|priorities/upvote|priorities/get-new-priority) return ;;
      arcane/copy|arcane/file-list|arcane/forall|arcane/jump-trash|arcane/read-magic|arcane/trash) return ;;
      psi/list-contacts|psi/read-contact) return ;;
      crypto/evoke-hash|crypto/hash|crypto/hashchant) return ;;
      translocation/enchant-portkey|translocation/follow-portkey|translocation/jump-to-marker) return ;;
      translocation/mark-location|translocation/open-portal|translocation/open-teletype) return ;;
      menu/system-menu) return ;;
    esac
    
    # Find line number of set -eu
    set_eu_line=$(grep -nE '^[[:space:]]*set +-[euo]*[eu][euo]*' "$spell" 2>/dev/null | head -1 | cut -d: -f1)
    
    if [ -z "$set_eu_line" ]; then
      # No set -eu found - will be caught by other test
      return
    fi
    
    # Check that ". env-clear" appears within 2 lines after set -eu
    start_line=$((set_eu_line + 1))
    end_line=$((set_eu_line + 2))
    
    if ! sed -n "${start_line},${end_line}p" "$spell" 2>/dev/null | grep -qE '^\. env-clear$|^[[:space:]]+\. env-clear$'; then
      printf '%s\n' "$rel_path"
    fi
  }
  
  tmpfile="${WIZARDRY_TMPDIR}/missing-env-clear-placement.txt"
  : > "$tmpfile"
  for_each_posix_spell check_env_clear_placement > "$tmpfile"
  
  violations=$(cat "$tmpfile" 2>/dev/null | head -20 | tr '\n' ', ' | sed 's/, $//')
  rm -f "$tmpfile"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="spells missing env-clear after set -eu: $violations (add '. env-clear' on line after 'set -eu')"
    return 1
  fi
  
  return 0
}

# --- Check: No mixed-case variables ---
# All variables must be either ALL_UPPERCASE or all_lowercase.
# Mixed case like SOME_var or some_VAR is not allowed as it's confusing and inconsistent.
# Environment variable REFERENCES (like ${PATH}, ${HOME}) are allowed to be uppercase.
# This enforces consistency in variable naming conventions.

test_no_mixed_case_variables() {
  violations=""
  
  check_mixed_case() {
    spell=$1
    name=$(basename "$spell")
    rel_path=${spell#"$ROOT_DIR/spells/"}
    
    # Skip exempt files
    case "$rel_path" in
      # Test infrastructure exempt
      .imps/test/*) return ;;
      # Bootstrap/arcana scripts have different rules
      .arcana/*) return ;;
    esac
    
    # Look for variable assignments and references with mixed case
    # Pattern: Variable name has both uppercase and lowercase (excluding environment vars in ${})
    # Match patterns like: SOME_var= or some_VAR= or ${SOME_var} or $SOME_var
    # Allow: ALL_CAPS, all_lowercase, ${ALL_CAPS} (env vars), $all_lowercase
    # Disallow: Mixed_Case, SOME_lower, some_UPPER
    
    # Find variable assignments with mixed case (has both upper and lower in same word)
    mixed_vars=$(grep -nE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=' "$spell" 2>/dev/null | \
      awk -F: '{
        # Extract variable name from assignment
        match($2, /^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=/, arr)
        if (arr[1] != "") {
          var = arr[1]
          # Check if variable has both uppercase and lowercase letters
          has_upper = (var ~ /[A-Z]/)
          has_lower = (var ~ /[a-z]/)
          if (has_upper && has_lower) {
            print $1 ":" var
          }
        }
      }' | head -5)
    
    # Find variable references with mixed case ${SOME_var} or $SOME_var
    # But exclude environment variable references that are conventionally uppercase
    mixed_refs=$(grep -nE '\$\{?[A-Za-z_][A-Za-z0-9_]*' "$spell" 2>/dev/null | \
      grep -v -E '\$\{?(PATH|HOME|USER|SHELL|TMPDIR|PWD|OLDPWD|IFS|CDPATH|LANG|LC_|TERM|DISPLAY|EDITOR|PAGER|VISUAL)' | \
      grep -v -E '\$\{?(ROOT_DIR|SPELLBOOK_DIR|MUD_DIR|MUD_PLAYER|WIZARDRY_|TEST_|NO_COLOR|BWRAP_|SANDBOX_|MACOS_)' | \
      grep -v -E '\$\{?(APT_|DNF_|YUM_|ZYPPER_|PACMAN_|APK_|PKGIN_|BREW_|NIX_)' | \
      grep -v -E '\$\{?(DETECT_|LOOK_|ASK_|INSTALL_|REMOVE_|START_|STOP_|RESTART_|ENABLE_|DISABLE_)' | \
      awk -F: '{
        line = $2
        while (match(line, /\$\{?([A-Za-z_][A-Za-z0-9_]*)/, arr)) {
          var = arr[1]
          has_upper = (var ~ /[A-Z]/)
          has_lower = (var ~ /[a-z]/)
          if (has_upper && has_lower) {
            print $1 ":" var
            break
          }
          line = substr(line, RSTART + RLENGTH)
        }
      }' | head -5)
    
    if [ -n "$mixed_vars" ] || [ -n "$mixed_refs" ]; then
      violations_found=""
      [ -n "$mixed_vars" ] && violations_found="$mixed_vars"
      [ -n "$mixed_refs" ] && violations_found="${violations_found:+$violations_found; }$mixed_refs"
      formatted=$(printf '%s\n' "$violations_found" | sed "s|^|$rel_path:|" | tr '\n' '; ' | sed 's/; $//')
      violations="${violations}${violations:+; }$formatted"
    fi
  }
  
  tmpfile="${WIZARDRY_TMPDIR}/mixed-case-vars.txt"
  : > "$tmpfile"
  for_each_posix_spell check_mixed_case > "$tmpfile"
  
  violations=$(cat "$tmpfile" 2>/dev/null | grep -v '^$' | head -10 | tr '\n' '; ' | sed 's/; $//')
  rm -f "$tmpfile"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="mixed-case variables found (must be ALL_UPPERCASE or all_lowercase): $violations"
    return 1
  fi
  
  return 0
}

# --- Warning Check: No parent directory references /../ outside cd commands ---
# Spells should use proper path resolution (cd with pwd -P) instead of bare /../
# references in path strings. This prevents fragile path construction.
# The pattern "cd -- \"$var/../..\" && pwd -P" is acceptable (proper resolution).
# The pattern "$var/../something" is problematic (no resolution).

test_warn_parent_dir_references() {
  found_refs=""
  
  check_parent_refs() {
    spell=$1
    name=$(basename "$spell")
    
    # Skip bootstrap/installation spells that need to find repo structure
    case $spell in
      */install/core/*|*/system/test-magic|*/spellcraft/lint-magic) return ;;
      */spellcraft/compile-spell|*/spellcraft/doppelganger) return ;;
      */menu/spellbook|*/system/verify-posix|*/menu/system/profile-tests) return ;;
      */cantrips/require-command) return ;;  # Bootstrap-related, finding install scripts
    esac
    
    # Look for /../ pattern that's NOT in a cd command followed by pwd -P
    # Pattern: /../ but not preceded by "cd " or "cd --" on same/previous line
    if grep -n '/\.\./' "$spell" 2>/dev/null | while IFS=: read -r line_num line_text; do
      # Check if this is part of a cd + pwd -P pattern (acceptable)
      if printf '%s' "$line_text" | grep -qE 'cd[[:space:]]+(--|[^&|;])*\$[^/]*/\.\./.*&&.*pwd -P'; then
        continue  # This is acceptable: cd with pwd -P
      fi
      
      # Check if line contains cd to parent dir (acceptable pattern)
      if printf '%s' "$line_text" | grep -qE 'cd[[:space:]]+(--|[^&|;])*[^)]*\.\./'; then
        continue  # Part of cd command (likely with pwd -P later)
      fi
      
      # If we get here, it's a bare /../ reference (potentially problematic)
      printf '%s:%s\n' "$name" "$line_num"
    done | head -1; then
      found_refs="${found_refs}${found_refs:+, }$name"
    fi
  }
  
  tmpfile="${WIZARDRY_TMPDIR}/parent-dir-refs.txt"
  : > "$tmpfile"
  for_each_posix_spell_no_imps check_parent_refs > "$tmpfile"
  
  found_refs=$(cat "$tmpfile" 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/, $//')
  rm -f "$tmpfile"
  
  if [ -n "$found_refs" ]; then
    printf 'WARNING: spells with parent directory references (/../) outside cd commands (use cd with pwd -P instead): %s\n' "$found_refs" >&2
  fi
  
  return 0
}

# Test: test output streams line-by-line (not buffered)
# Verifies that PASS/FAIL lines appear as subtests complete, not all at once
# This is a fast regression test for the stdbuf fix in test-magic
test_output_streams_line_by_line() {
  # Verify stdbuf is available (core requirement for unbuffered output)
  if ! command -v stdbuf >/dev/null 2>&1; then
    # Without stdbuf, output may be buffered but tests will still work
    # Just skip this validation
    return 0
  fi
  
  # Create a simple test that outputs PASS lines with timing
  tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/streaming-test.XXXXXX")
  test_file="$tmpdir/streaming-test.sh"
  
  cat > "$test_file" << 'EOF'
#!/bin/sh
printf 'PASS #1 first\n'
sleep 0.15
printf 'PASS #2 second\n'
sleep 0.15
printf 'PASS #3 third\n'
EOF
  
  chmod +x "$test_file"
  
  # Run with stdbuf (as test-magic does) and capture with timestamps
  output_file="$tmpdir/output.txt"
  stdbuf -oL sh "$test_file" 2>&1 | while IFS= read -r line; do
    printf '%s|%s\n' "$(date +%s.%N)" "$line"
  done > "$output_file"
  
  # Extract timestamps for PASS lines
  pass_times=$(grep '|PASS ' "$output_file" | cut -d'|' -f1)
  pass_count=$(printf '%s\n' "$pass_times" | grep -c '^' || echo 0)
  
  # Verify we got 3 PASS lines
  if [ "$pass_count" -ne 3 ]; then
    rm -rf "$tmpdir"
    TEST_FAILURE_REASON="expected 3 PASS lines, got $pass_count"
    return 1
  fi
  
  # Check timing spread: first and last PASS should be at least 0.2s apart
  first_time=$(printf '%s\n' "$pass_times" | head -1)
  last_time=$(printf '%s\n' "$pass_times" | tail -1)
  
  # Use awk for floating point comparison
  is_spaced=$(awk "BEGIN {print ($last_time - $first_time >= 0.2) ? 1 : 0}")
  
  rm -rf "$tmpdir"
  
  if [ "$is_spaced" -ne 1 ]; then
    TEST_FAILURE_REASON="PASS lines appeared too quickly, indicating buffered output"
    return 1
  fi
  
  return 0
}

# --- Run all test cases ---

_run_test_case "no duplicate spell names" test_no_duplicate_spell_names
_run_test_case "menu spells require menu command" test_menu_spells_require_menu
_run_test_case "spells have standard help handlers" test_spells_have_help_usage_handlers
_run_test_case "warn about full paths to spells" test_warn_full_paths_to_spells
_run_test_case "test files have matching spells" test_test_files_have_matching_spells
_run_test_case "tests rely only on imps for helpers" test_tests_use_imps_for_helpers
_run_test_case "scripts using declared globals have set -u" test_scripts_using_globals_have_set_u
_run_test_case "declare-globals has exactly 4 globals" test_declare_globals_count
_run_test_case "no undeclared globals exported" test_no_undeclared_global_exports
_run_test_case "no global declarations outside declare-globals" test_no_global_declarations_outside_declare_globals
_run_test_case "no pseudo-globals stored in rc files" test_no_pseudo_globals_in_rc_files
_run_test_case "imps follow one-function-or-zero rule" test_imps_follow_function_rule
_run_test_case "imps have opening comments" test_imps_have_opening_comments
_run_test_case "bootstrap spells have identifying comment" test_bootstrap_spells_identified
_run_test_case "spells follow function discipline" test_spells_follow_function_discipline
_run_test_case "no function name collisions" test_no_function_name_collisions
_run_test_case "spells have true name functions" test_spells_have_true_name_functions
_run_test_case "spells require wrapper functions" test_spells_require_wrapper_functions
_run_test_case "spells have limited flags" test_spells_have_limited_flags
_run_test_case "spells have limited positional arguments" test_spells_have_limited_positional_args
_run_test_case "no all-caps variable assignments" test_no_allcaps_variable_assignments
_run_test_case "no mixed-case variables" test_no_mixed_case_variables
_run_test_case "scripts have set -eu early" test_scripts_have_set_eu_early
_run_test_case "spells source env-clear after set -eu" test_spells_source_env_clear_after_set_eu
_run_test_case "warn about parent directory references" test_warn_parent_dir_references
_run_test_case "test output streams line-by-line" test_output_streams_line_by_line

# --- Check: Stub imps have correct self-execute patterns ---
# Stub imps must match both */stub-name and */name for symlink usage
# This ensures tests can create symlinks without the stub- prefix
test_stub_imps_have_correct_patterns() {
  # Skip in doppelganger mode - grep patterns behave differently
  if [ "${WIZARDRY_OS_LABEL:-}" = "doppelganger" ]; then
    _test_skip "stub imps have correct self-execute patterns" "skipped in doppelganger mode"
    return 0
  fi
  
  failures=""
  
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty await-keypress; do
    stub_path="$ROOT_DIR/spells/.imps/test/stub-$stub"
    
    # Check file exists
    if [ ! -f "$stub_path" ]; then
      failures="${failures}${failures:+, }stub-$stub (missing)"
      continue
    fi
    
    # Check for case statement
    if ! grep -qE "case.*\\\$0.*in" "$stub_path"; then
      failures="${failures}${failures:+, }stub-$stub (no case statement)"
      continue
    fi
    
    # Check that the case pattern includes both the stub name and unprefixed name
    # The pattern should be like: */stub-name|*/name) or */name|*/stub-name)
    unprefixed=$(printf '%s' "$stub" | sed 's/^stub-//')
    
    # Check if both patterns exist in the file (order doesn't matter)
    # Note: Allow optional whitespace before the pattern
    has_stub_pattern=0
    has_unprefixed_pattern=0
    
    if grep -qE "[[:space:]]*\*/stub-$stub[|)]" "$stub_path"; then
      has_stub_pattern=1
    fi
    
    if grep -qE "[[:space:]]*\*/$unprefixed[|)]" "$stub_path"; then
      has_unprefixed_pattern=1
    fi
    
    if [ "$has_stub_pattern" -eq 0 ]; then
      failures="${failures}${failures:+, }stub-$stub (missing */stub-$stub pattern)"
    elif [ "$has_unprefixed_pattern" -eq 0 ]; then
      failures="${failures}${failures:+, }stub-$stub (missing */$unprefixed pattern)"
    fi
  done
  
  if [ -n "$failures" ]; then
    TEST_FAILURE_REASON="stub imps with incorrect self-execute patterns: $failures"
    return 1
  fi
  
  return 0
}

_run_test_case "stub imps have correct self-execute patterns" test_stub_imps_have_correct_patterns

# ==============================================================================
# META-TESTS - Testing the testing system itself
# These tests validate that the testing infrastructure is properly architected
# ==============================================================================

# META: Baseline PATH must be established before any commands
test_bootstrap_sets_baseline_path() {
  # Verify test-bootstrap content has PATH setup before set -eu
  bootstrap_file="$ROOT_DIR/spells/.imps/test/test-bootstrap"
  
  # Find line number of "set -eu"
  set_eu_line=$(grep -n "^set -eu" "$bootstrap_file" | head -1 | cut -d: -f1)
  
  # Find line number of PATH setup
  path_line=$(grep -n "baseline_path=" "$bootstrap_file" | head -1 | cut -d: -f1)
  
  # PATH setup must come before set -eu
  if [ -z "$set_eu_line" ] || [ -z "$path_line" ]; then
    TEST_FAILURE_REASON="Could not find set -eu or PATH setup in test-bootstrap"
    return 1
  fi
  
  if [ "$path_line" -ge "$set_eu_line" ]; then
    TEST_FAILURE_REASON="PATH setup (line $path_line) must come before set -eu (line $set_eu_line)"
    return 1
  fi
  
  return 0
}

# META: Sandbox unavailability must not fail tests
test_sandbox_fallback_is_graceful() {
  # Verify BWRAP_AVAILABLE flag exists and fallback logic is present
  if [ -z "${BWRAP_AVAILABLE-}" ]; then
    TEST_FAILURE_REASON="BWRAP_AVAILABLE flag not set by test-bootstrap"
    return 1
  fi
  
  # If bwrap is not available, verify we have a reason
  if [ "$BWRAP_AVAILABLE" -eq 0 ]; then
    if [ -z "${BWRAP_REASON-}" ]; then
      TEST_FAILURE_REASON="BWRAP_AVAILABLE=0 but no BWRAP_REASON set"
      return 1
    fi
  fi
  
  return 0
}

# META: Test output must stream line-by-line
test_test_magic_uses_stdbuf() {
  test_magic_file="$ROOT_DIR/spells/system/test-magic"
  
  # Check if stdbuf is available and used
  if ! command -v stdbuf >/dev/null 2>&1; then
    # stdbuf not available - test is skipped but requirement noted
    return 0
  fi
  
  # Verify test-magic mentions stdbuf
  if ! grep -q "stdbuf" "$test_magic_file"; then
    TEST_FAILURE_REASON="test-magic doesn't use stdbuf for line-buffered output"
    return 1
  fi
  
  return 0
}

# META: Test failures must report clearly
test_test_bootstrap_provides_failure_reporting() {
  # Verify TEST_FAILURE_REASON is used in test framework
  if ! grep -q "TEST_FAILURE_REASON" "$ROOT_DIR/spells/.imps/test/boot/"* 2>/dev/null; then
    TEST_FAILURE_REASON="Test framework doesn't support TEST_FAILURE_REASON"
    return 1
  fi
  
  return 0
}

# META: die imp must work correctly with word-of-binding
test_die_imp_uses_return_not_exit() {
  die_file="$ROOT_DIR/spells/.imps/out/die"
  
  # Verify die uses return, not exit
  if grep -q "^[[:space:]]*exit " "$die_file"; then
    TEST_FAILURE_REASON="die imp uses 'exit' instead of 'return' (breaks word-of-binding)"
    return 1
  fi
  
  if ! grep -q "^[[:space:]]*return " "$die_file"; then
    TEST_FAILURE_REASON="die imp doesn't use 'return' (required for word-of-binding)"
    return 1
  fi
  
  return 0
}

# META: fail imp must NOT exit script
test_fail_imp_returns_error_code() {
  fail_file="$ROOT_DIR/spells/.imps/out/fail"
  
  # Verify fail uses return 1, not exit
  if grep -q "^[[:space:]]*exit " "$fail_file"; then
    TEST_FAILURE_REASON="fail imp uses 'exit' (should use 'return' to continue execution)"
    return 1
  fi
  
  if ! grep -q "return 1" "$fail_file"; then
    TEST_FAILURE_REASON="fail imp doesn't return 1"
    return 1
  fi
  
  return 0
}

# META: Platform detection must work
test_platform_detection_available() {
  # Verify detect-distro spell exists
  if [ ! -f "$ROOT_DIR/spells/divination/detect-distro" ]; then
    TEST_FAILURE_REASON="detect-distro spell not found"
    return 1
  fi
  
  # Verify it's executable
  if [ ! -x "$ROOT_DIR/spells/divination/detect-distro" ]; then
    TEST_FAILURE_REASON="detect-distro is not executable"
    return 1
  fi
  
  return 0
}

# META: banish spell exists and is the environment preparer
test_banish_spell_exists_and_is_executable() {
  if [ ! -f "$ROOT_DIR/spells/system/banish" ]; then
    TEST_FAILURE_REASON="banish spell not found"
    return 1
  fi
  
  if [ ! -x "$ROOT_DIR/spells/system/banish" ]; then
    TEST_FAILURE_REASON="banish spell is not executable"
    return 1
  fi
  
  # Verify banish has usage that mentions environment preparation
  if ! grep -qi "environment" "$ROOT_DIR/spells/system/banish"; then
    TEST_FAILURE_REASON="banish doesn't mention environment preparation"
    return 1
  fi
  
  return 0
}

# META: test-bootstrap checks environment
test_test_bootstrap_checks_environment() {
  bootstrap_file="$ROOT_DIR/spells/.imps/test/test-bootstrap"
  
  # Verify it sets up PATH
  if ! grep -q "PATH=" "$bootstrap_file"; then
    TEST_FAILURE_REASON="test-bootstrap doesn't set up PATH"
    return 1
  fi
  
  # Verify it sets up WIZARDRY_DIR
  if ! grep -q "WIZARDRY_DIR" "$bootstrap_file"; then
    TEST_FAILURE_REASON="test-bootstrap doesn't set up WIZARDRY_DIR"
    return 1
  fi
  
  return 0
}

# Run meta-tests
_run_test_case "META: baseline PATH before set -eu" test_bootstrap_sets_baseline_path
_run_test_case "META: sandbox fallback is graceful" test_sandbox_fallback_is_graceful
_run_test_case "META: test-magic uses stdbuf" test_test_magic_uses_stdbuf
_run_test_case "META: test framework supports failure reporting" test_test_bootstrap_provides_failure_reporting
_run_test_case "META: die imp uses return for word-of-binding" test_die_imp_uses_return_not_exit
_run_test_case "META: fail imp returns error code" test_fail_imp_returns_error_code
_run_test_case "META: platform detection available" test_platform_detection_available
_run_test_case "META: banish spell exists and is executable" test_banish_spell_exists_and_is_executable
_run_test_case "META: test-bootstrap checks environment" test_test_bootstrap_checks_environment

_finish_tests
