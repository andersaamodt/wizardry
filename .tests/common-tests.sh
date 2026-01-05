#!/bin/sh
# Common structural and behavioral checks that apply across all spells and imps.
# Run first as part of test-magic to catch systemic issues early.
#
# This file contains cross-cutting tests that verify properties across the
# entire spellbook. Style/opinionated checks belong in vet-spell instead.
# Note: POSIX compliance (shebang, bashisms) is checked by verify-posix.

common_tests_usage() {
  cat <<'USAGE'
Usage: common-tests.sh [SPELL_PATH...]

Run common structural and behavioral checks that apply across all spells.

Arguments:
  SPELL_PATH     Optional spell path(s) to test (e.g., spells/cantrips/ask-yn)
                 If provided, only tests the specified spells.
                 If omitted, tests all spells in the repository.

Examples:
  common-tests.sh                              # Test all spells
  common-tests.sh spells/cantrips/ask-yn       # Test one spell
  common-tests.sh spells/cantrips/ask-yn spells/cantrips/ask-text  # Test multiple

Note: This is an exception to the .tests/ naming schema. It does not mirror
a spell in spells/ - it's a special test suite for cross-cutting checks.
USAGE
}

case "${1-}" in
--help|--usage|-h)
  common_tests_usage
  exit 0
  ;;
esac

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
# Ensure each spell provides a --help|--usage|-h) case handler
# Note: Usage function check is handled by lint-magic, not here
test_spells_have_help_usage_handlers() {
  missing_handler=""

  check_help_handler() {
    spell=$1
    rel_path=${spell#"$ROOT_DIR/spells/"}

    if ! grep -qF -- '--help|--usage|-h)' "$spell" 2>/dev/null; then
      missing_handler="${missing_handler:+$missing_handler, }$rel_path"
    fi
  }
  
  for_each_posix_spell_no_imps check_help_handler

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
    
    # Skip test infrastructure - test-bootstrap is complex test framework
    rel_path=${imp#"$ROOT_DIR/spells/.imps/"}
    case "$rel_path" in
      test/test-bootstrap) continue ;;
    esac
    
    # Count function definitions
    # Pattern matches: name() { or name () {
    func_count=$(grep -cE '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{' "$imp" 2>/dev/null) || func_count=0
    
    # NEW REQUIREMENT: Imps must have 0 functions (flat scripts only)
    if [ "$func_count" -gt 0 ]; then
      printf '%s (has %s functions, should be 0)\n' "$rel_path" "$func_count"
      continue
    fi
    
  done > "${WIZARDRY_TMPDIR}/imp-structure-violations.txt"
  
  violations=$(cat "${WIZARDRY_TMPDIR}/imp-structure-violations.txt" 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/, $//')
  rm -f "${WIZARDRY_TMPDIR}/imp-structure-violations.txt"
  
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="imps violating function rule (must have 0 functions): $violations"
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
  tmpfile_violations=$(mktemp "${WIZARDRY_TMPDIR}/func-violations.XXXXXX")
  
  # NEW REQUIREMENT: Spells must have at most 1 function total
  # Hardcoded exceptions for spells documented in EXEMPTIONS.md
  exempted_spells="
spellcraft/lint-magic
menu/spellbook
cantrips/menu
cantrips/colors
cantrips/fathom-cursor
cantrips/await-keypress
psi/read-contact
menu/mud
menu/mud-settings
menu/main-menu
menu/system/profile-tests
.arcana/mud/cd
.arcana/core/install-core
.arcana/core/install-bwrap
.arcana/bitcoin/configure-bitcoin
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
    # Pattern matches both inline "func() {" and multiline "func()" followed by "{"
    func_count=$(grep -cE '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)([[:space:]]*\{|[[:space:]]*$)' "$spell" 2>/dev/null || true)
    func_count=${func_count:-0}
    
    # NEW REQUIREMENT: Fail on more than 1 function (flat file paradigm)
    if [ "$func_count" -gt 1 ]; then
      printf '%s(%s)\n' "$rel_path" "$func_count" >> "$tmpfile_violations"
    fi
  }
  
  for_each_posix_spell_no_imps check_function_discipline
  
  # Read and format results
  violations=$(head -50 "$tmpfile_violations" 2>/dev/null | tr '\n' ', ' | sed 's/, $//')
  
  rm -f "$tmpfile_violations"
  
  # Fail on more than 1 function
  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="spells with more than 1 function (must have at most 1): $violations"
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
# definitions from shared imps (e.g., has, there). This is expected and acceptable
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

# --- DEPRECATED: Spells and imps have true name functions ---
# DEPRECATED: This test checked for function wrappers with "true names"
# No longer applicable - spells and imps are now flat, linear scripts without function wrappers
# Kept for historical reference but not executed

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

# --- DEPRECATED: True name functions do not use leading underscores ---
# DEPRECATED: This test checked that function names matched filenames
# No longer applicable - spells and imps are now flat, linear scripts without function wrappers
# Kept for historical reference but not executed

test_true_names_have_no_leading_underscore() {
  violations=""

  check_true_name_prefix() {
    spell=$1
    name=$(basename "$spell")
    rel_path=${spell#"$ROOT_DIR/spells/"}
    true_name=$(printf '%s' "$name" | sed 's/-/_/g')
    leading_name="_$true_name"

    if grep -qE "^[[:space:]]*${leading_name}[[:space:]]*\(\)" "$spell" 2>/dev/null; then
      printf '%s (uses %s)\n' "$rel_path" "$leading_name"
    fi
  }

  tmpfile="${WIZARDRY_TMPDIR}/leading-underscore-true-names.txt"
  : > "$tmpfile"
  for_each_posix_spell check_true_name_prefix > "$tmpfile"

  violations=$(cat "$tmpfile" 2>/dev/null | head -30 | tr '\n' ', ' | sed 's/, $//')
  rm -f "$tmpfile"

  if [ -n "$violations" ]; then
    TEST_FAILURE_REASON="true name functions must not use leading underscores: $violations"
    return 1
  fi
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
  
  # Exempted spells that legitimately need 4+ flags
  # Must be documented in EXEMPTIONS.md with justification
  exempted_spells="
    system/test-magic
  "
  
  tmpfile_2=$(mktemp "${WIZARDRY_TMPDIR}/flag-warn-2.XXXXXX")
  tmpfile_3=$(mktemp "${WIZARDRY_TMPDIR}/flag-warn-3.XXXXXX")
  tmpfile_4plus=$(mktemp "${WIZARDRY_TMPDIR}/flag-viol-4plus.XXXXXX")
  
  check_flags() {
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
    
    # Count distinct flag options by looking at both case and if patterns
    # Exclude standard --help|--usage|-h, catch-all -*, -- (end of options), and --- (dividers)
    # OPTIMIZED: Single awk pass instead of multiple grep/awk passes
    flag_count=$(awk '
      BEGIN { seen_flags = ""; flag_count = 0 }
      
      # Track if we are in argument parsing section (case or while loop)
      /while.*\$.*-gt 0/ { in_args = 1 }
      /case.*\$\{?1/ { in_args = 1 }
      in_args && /^[[:space:]]*esac[[:space:]]*$/ && parsing_done == 0 { 
        parsing_done = 1
        in_args = 0
      }
      
      # When in argument parsing, capture flag patterns from case statements
      in_args && /^[[:space:]]+(-[a-zA-Z]|--[a-zA-Z-]+)(\||[[:space:]]*\))/ {
        # Skip help flags, catch-all, and dividers in a single check
        if ($0 ~ /--help|--usage|-h\)|^\s+-\*\)|^\s+--\)|^\s+---\)/) next
        
        # Extract flag name
        if (match($0, /(--[a-zA-Z-]+|-[a-zA-Z])/)) {
          flag = substr($0, RSTART, RLENGTH)
        } else {
          flag = ""
        }
        if (flag != "" && index(seen_flags, flag) == 0) {
          seen_flags = seen_flags " " flag
          flag_count++
        }
      }
      
      # Also check for if-based flag handling: if [ "$1" = "--flag" ]
      /if[[:space:]]*\[[[:space:]]*["\$]*\{?1/ && /(=|==)[[:space:]]*["'\''](--[a-zA-Z-]+|-[a-zA-Z])["'\'']/ {
        # Skip help flags and dividers
        if ($0 ~ /--help|--usage|-h|---/) next
        
        # Extract flag name
        if (match($0, /(--[a-zA-Z-]+|-[a-zA-Z])/)) {
          flag = substr($0, RSTART, RLENGTH)
        } else {
          flag = ""
        }
        if (flag != "" && index(seen_flags, flag) == 0) {
          seen_flags = seen_flags " " flag
          flag_count++
        }
      }
      
      END { print flag_count }
    ' "$spell" 2>/dev/null)
    
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
      grep -v -E '(ASK_CANTRIP_INPUT|CHOOSE_INPUT_MODE|MENU_LOOP_LIMIT|REQUIRE_COMMAND|MENU_LOG)' | \
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
    
    # Auto-detect castable/uncastable pattern or traditional word-of-binding pattern:
    # Modern flat pattern (preferred):
    #   - No function wrappers
    #   - set -eu at top level (after help handler)
    #   - Code executes directly
    # Legacy patterns (deprecated but still exist in some files):
    #   - Wrapper function with castable/uncastable
    #   - Self-execute case statement
    # If legacy pattern present, set can be inside wrapper
    
    # Convert filename to function name (hyphens to underscores)
    func_name=$(printf '%s' "$name" | tr '-' '_')
    
    # Check for wrapper function definition (legacy pattern)
    has_wrapper=0
    if grep -qE "^[[:space:]]*${func_name}[[:space:]]*\(\)" "$spell" 2>/dev/null; then
      has_wrapper=1
    fi
    
    # Check for castable/uncastable pattern
    has_castable_pattern=0
    if grep -qE '^[[:space:]]*castable[[:space:]]+"?\$@"?' "$spell" 2>/dev/null || \
       grep -qE '^[[:space:]]*uncastable([[:space:]]|$)' "$spell" 2>/dev/null; then
      has_castable_pattern=1
    fi
    
    # Check for traditional self-execute pattern
    has_self_execute=0
    if grep -qE 'case[[:space:]]+"\$0"[[:space:]]+in' "$spell" 2>/dev/null && \
       grep -qE "\*/${name}\)" "$spell" 2>/dev/null; then
      has_self_execute=1
    fi
    
    # If word-of-binding pattern detected (castable/uncastable OR traditional), 
    # check for set -eu or set +eu anywhere in the file
    if [ "$has_wrapper" = "1" ] && { [ "$has_castable_pattern" = "1" ] || [ "$has_self_execute" = "1" ]; }; then
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
      # Autocast spells exempt (use autocast pattern, not env-clear)
      cantrips/colors) return ;;
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
        var = $2
        sub(/^[[:space:]]*/, "", var)
        sub(/=.*/, "", var)
        if (var != "") {
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
        while (match(line, /\$[{]?[A-Za-z_][A-Za-z0-9_]*/)) {
          var = substr(line, RSTART, RLENGTH)
          sub(/^\$[{]?/, "", var)
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

# --- Test: common-tests shows help ---
# Verify that common-tests.sh responds to --help flag
test_common_tests_shows_help() {
  # Run common-tests.sh with --help flag
  output=$(sh "$ROOT_DIR/.tests/common-tests.sh" --help 2>&1)
  exit_code=$?
  
  if [ "$exit_code" -ne 0 ]; then
    TEST_FAILURE_REASON="--help should exit with code 0"
    return 1
  fi
  
  # Check that help output contains usage information
  if ! printf '%s' "$output" | grep -q "Usage:"; then
    TEST_FAILURE_REASON="--help output missing Usage:"
    return 1
  fi
  
  if ! printf '%s' "$output" | grep -q "common-tests.sh"; then
    TEST_FAILURE_REASON="--help output missing script name"
    return 1
  fi
  
  return 0
}

# --- Run all test cases ---

run_test_case "common-tests shows help" test_common_tests_shows_help
run_test_case "no duplicate spell names" test_no_duplicate_spell_names
run_test_case "menu spells require menu command" test_menu_spells_require_menu
run_test_case "spells have standard help handlers" test_spells_have_help_usage_handlers
run_test_case "warn about full paths to spells" test_warn_full_paths_to_spells
run_test_case "test files have matching spells" test_test_files_have_matching_spells
run_test_case "tests rely only on imps for helpers" test_tests_use_imps_for_helpers
run_test_case "scripts using declared globals have set -u" test_scripts_using_globals_have_set_u
run_test_case "declare-globals has exactly 4 globals" test_declare_globals_count
run_test_case "no undeclared globals exported" test_no_undeclared_global_exports
run_test_case "no global declarations outside declare-globals" test_no_global_declarations_outside_declare_globals
run_test_case "no pseudo-globals stored in rc files" test_no_pseudo_globals_in_rc_files
run_test_case "imps follow one-function-or-zero rule" test_imps_follow_function_rule
run_test_case "imps have opening comments" test_imps_have_opening_comments
run_test_case "bootstrap spells have identifying comment" test_bootstrap_spells_identified
run_test_case "spells follow function discipline" test_spells_follow_function_discipline
run_test_case "no function name collisions" test_no_function_name_collisions
# --- DEPRECATED: True name function tests ---
# These tests checked for function wrappers with "true names"
# No longer applicable - spells and imps are now flat, linear scripts
# Kept for historical reference but not executed

# test_spells_have_true_name_functions() - DEPRECATED
# test_true_names_have_no_leading_underscore() - DEPRECATED  
# test_spells_require_wrapper_functions() - DEPRECATED

# Calls commented out (no longer applicable):
# run_test_case "spells have true name functions" test_spells_have_true_name_functions
# run_test_case "true names do not use leading underscores" test_true_names_have_no_leading_underscore
# run_test_case "spells require wrapper functions" test_spells_require_wrapper_functions
run_test_case "spells have limited flags" test_spells_have_limited_flags
run_test_case "spells have limited positional arguments" test_spells_have_limited_positional_args
run_test_case "no all-caps variable assignments" test_no_allcaps_variable_assignments
run_test_case "no mixed-case variables" test_no_mixed_case_variables
run_test_case "scripts have set -eu early" test_scripts_have_set_eu_early
run_test_case "spells source env-clear after set -eu" test_spells_source_env_clear_after_set_eu
run_test_case "warn about parent directory references" test_warn_parent_dir_references
run_test_case "test output streams line-by-line" test_output_streams_line_by_line

# --- Check: Stub imps have correct self-execute patterns ---
# Stub imps must match both */stub-name and */name for symlink usage
# This ensures tests can create symlinks without the stub- prefix
test_stub_imps_have_correct_patterns() {
  # Skip in doppelganger mode - grep patterns behave differently
  if [ "${WIZARDRY_OS_LABEL:-}" = "doppelganger" ]; then
    test_skip "stub imps have correct self-execute patterns" "skipped in doppelganger mode"
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

run_test_case "stub imps have correct self-execute patterns" test_stub_imps_have_correct_patterns

# ==============================================================================
# SPELL INVOCATION REQUIREMENTS - Optional Invocation Declarations
# Spells may optionally declare "uncastable" if they need to be sourced.
# Spells may optionally declare "autocast" for auto-execution patterns.
# The "castable" declaration is deprecated and should be removed.
# ==============================================================================

# Check that spells don't have deprecated castable or multiple declarations
test_spells_no_deprecated_invocation_declarations() {
  failures=""
  
  # Check all spell files (not imps, not tests)
  while IFS= read -r spell_file; do
    # Skip non-shell scripts
    if ! is_posix_shell_script "$spell_file"; then
      continue
    fi
    
    # Get spell name for reporting
    spell_name=${spell_file#"$ROOT_DIR/spells/"}
    
    # Skip imps - they are flat, linear scripts (no wrapper functions)
    # Skip bootstrap spells in .arcana/core
    case "$spell_name" in
      .imps/*) continue ;;
      .arcana/core/*) continue ;;
    esac
    
    # Check if spell has invocation declarations
    has_castable=0
    has_uncastable=0
    has_autocast=0
    
    if grep -q "^castable" "$spell_file" 2>/dev/null; then
      has_castable=1
    fi
    
    if grep -q "^uncastable" "$spell_file" 2>/dev/null; then
      has_uncastable=1
    fi
    
    if grep -q "^autocast" "$spell_file" 2>/dev/null; then
      has_autocast=1
    fi
    
    # Count declarations
    declaration_count=$((has_castable + has_uncastable + has_autocast))
    
    # Warn if spell has deprecated castable (should be removed)
    if [ "$has_castable" -eq 1 ]; then
      failures="${failures}${failures:+, }$spell_name (has deprecated 'castable' declaration)"
    fi
    
    # Error if spell has multiple declarations (shouldn't have both uncastable and autocast)
    if [ "$declaration_count" -gt 1 ]; then
      failures="${failures}${failures:+, }$spell_name (multiple invocation declarations)"
    fi
  done < "$SPELL_LIST_CACHE"
  
  if [ -n "$failures" ]; then
    TEST_FAILURE_REASON="spells with deprecated or multiple invocation declarations: $failures"
    return 1
  fi
  
  return 0
}

run_test_case "spells have no deprecated invocation declarations" test_spells_no_deprecated_invocation_declarations

# --- Check: All spells respond to --help flag ---
# Every spell must support --help, --usage, or -h flags
# This eliminates duplication in individual test files
test_all_spells_respond_to_help() {
  failures=""
  
  check_help_flag() {
    spell=$1
    rel_path=${spell#"$ROOT_DIR/spells/"}
    
    # Try each help flag variant
    for flag in --help --usage -h; do
      # Run spell with help flag and capture output
      output=$("$spell" "$flag" 2>&1)
      exit_code=$?
      
      # Spell must exit with code 0 for help
      if [ "$exit_code" -ne 0 ]; then
        failures="${failures}${failures:+, }$rel_path ($flag: exit code $exit_code)"
        return
      fi
      
      # Output must contain "Usage:" keyword
      if ! printf '%s' "$output" | grep -qi "usage:"; then
        failures="${failures}${failures:+, }$rel_path ($flag: missing Usage:)"
        return
      fi
      
      # Found working help flag, move to next spell
      return
    done
    
    # If we get here, none of the help flags worked
    failures="${failures}${failures:+, }$rel_path (no help flags work)"
  }
  
  for_each_posix_spell_no_imps check_help_flag
  
  if [ -n "$failures" ]; then
    TEST_FAILURE_REASON="spells not responding to --help flags: $failures"
    return 1
  fi
  
  return 0
}

run_test_case "all spells respond to --help flag" test_all_spells_respond_to_help

# ==============================================================================
# SPELL-LEVELS COVERAGE TESTS - Validate level organization
# These tests ensure all spells/imps are categorized and no empty levels exist
# ==============================================================================

# --- Check: spell-levels has no empty levels ---
# Every level must have either spells or imps (or both)
# This prevents gaps in the level system
test_spell_levels_no_empty_levels() {
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
    TEST_FAILURE_REASON="found empty levels: $(printf '%b' "$empty_levels" | tr '\n' ', ' | sed 's/, $//')"
    return 1
  fi
  return 0
}

# --- Check: all spells are categorized in spell-levels ---
# Every spell file must appear in at least one level
# This prevents spells from being orphaned/forgotten
test_all_spells_categorized_in_spell_levels() {
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
    TEST_FAILURE_REASON="spells not categorized in spell-levels: $(printf '%b' "$uncategorized" | head -10 | tr '\n' ', ' | sed 's/, $//')"
    return 1
  fi
  return 0
}

# --- Check: all imps are categorized in spell-levels ---
# Every imp file must appear in at least one level
# This prevents imps from being orphaned/forgotten
test_all_imps_categorized_in_spell_levels() {
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
    TEST_FAILURE_REASON="imps not categorized in spell-levels: $(printf '%b' "$uncategorized" | head -10 | tr '\n' ', ' | sed 's/, $//')"
    return 1
  fi
  return 0
}

run_test_case "spell-levels has no empty levels" test_spell_levels_no_empty_levels
run_test_case "all spells are categorized in spell-levels" test_all_spells_categorized_in_spell_levels  
run_test_case "all imps are categorized in spell-levels" test_all_imps_categorized_in_spell_levels

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

# META: Pocket dimension must be available outside GitHub Actions
test_pocket_dimension_available() {
  if [ "${GITHUB_ACTIONS-}" = "true" ]; then
    return 0
  fi

  if ! command -v pocket-dimension >/dev/null 2>&1; then
    TEST_FAILURE_REASON="pocket-dimension not found in PATH"
    return 1
  fi

  if ! pocket-dimension --check >/dev/null 2>&1; then
    TEST_FAILURE_REASON="pocket-dimension check failed"
    return 1
  fi

  return 0
}

# META: Test output must stream line-by-line
test_test_magic_uses_stdbuf() {
  test_magic_file="$ROOT_DIR/spells/.wizardry/test-magic"
  
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

# ==============================================================================
# PARADIGM ENFORCEMENT: Spells must NOT preload their own prerequisites
# ==============================================================================

# Test: Spells must not preload their own prerequisites
# Spells should call require_wizardry and fail if wizardry isn't available.
# They should NOT include blocks like:
#   if ! command -v require_wizardry >/dev/null 2>&1; then
#     [ -f "$_i/require-wizardry" ] && . "$_i/require-wizardry"
#   fi
test_spells_do_not_preload_prerequisites() {
  failed_spells=""
  
  while IFS= read -r spell_file; do
    [ -n "$spell_file" ] || continue
    [ -f "$spell_file" ] || continue
    
    # Skip test infrastructure and bootstrap scripts (install, .arcana, test imps)
    case "$spell_file" in
      */test/*|*/install/*|*/.arcana/*) continue ;;
    esac
    
    # Skip non-POSIX scripts
    is_posix_shell_script "$spell_file" || continue
    
    spell_name=$(basename "$spell_file")
    
    # Check for prerequisite preloading patterns
    # Pattern: if ! command -v <prerequisite> check followed by sourcing
    if grep -q "if ! command -v require_wizardry" "$spell_file" || \
       grep -q "if ! command -v env_clear" "$spell_file" || \
       grep -q "if ! command -v die" "$spell_file" || \
       grep -q "if ! command -v warn" "$spell_file" || \
       grep -q "if ! command -v fail" "$spell_file"; then
      
      # Check if it's actually sourcing the imp (preloading)
      if grep -A 10 "if ! command -v" "$spell_file" | grep -q '\. .*require-wizardry\|. .*env-clear\|. .*die\|. .*warn\|. .*fail'; then
        failed_spells="${failed_spells}${spell_name} "
      fi
    fi
  done < "$SPELL_LIST_CACHE"
  
  if [ -n "$failed_spells" ]; then
    TEST_FAILURE_REASON="Spells must not preload prerequisites (use require_wizardry and fail if unavailable): $failed_spells"
    return 1
  fi
  
  return 0
}

# Test: Spells must not source files by direct path (except castable/uncastable)
# Spells should use function names, not path-based sourcing like ". spells/.imps/out/say"
# Exception: castable/uncastable loading and bootstrap scripts are allowed
test_spells_do_not_source_by_path() {
  failed_spells=""
  
  while IFS= read -r spell_file; do
    [ -n "$spell_file" ] || continue
    [ -f "$spell_file" ] || continue
    
    # Skip test infrastructure and bootstrap scripts (they're allowed to use paths)
    case "$spell_file" in
      */test/*|*/install/*|*/.arcana/*) continue ;;
    esac
    
    # Skip non-POSIX scripts
    is_posix_shell_script "$spell_file" || continue
    
    spell_name=$(basename "$spell_file")
    
    # Look for path-based sourcing, excluding castable/uncastable which are legitimate
    # Pattern: . "$variable"/spells/.imps/... or . spells/.imps/...
    # But exclude: . "$_i/castable" and . "$_i/uncastable"
    if grep -E '\. .*/spells/\.imps/|. .*/spells/\.imps/' "$spell_file" | \
       grep -v '/castable"' | grep -v '/uncastable"' | grep -v '^[[:space:]]*#' >/dev/null 2>&1; then
      failed_spells="${failed_spells}${spell_name} "
    fi
  done < "$SPELL_LIST_CACHE"
  
  if [ -n "$failed_spells" ]; then
    TEST_FAILURE_REASON="Spells must not source by path (use function names, except castable/uncastable): $failed_spells"
    return 1
  fi
  
  return 0
}

# Run meta-tests
run_test_case "META: baseline PATH before set -eu" test_bootstrap_sets_baseline_path
run_test_case "META: pocket dimension is available" test_pocket_dimension_available
run_test_case "META: test-magic uses stdbuf" test_test_magic_uses_stdbuf
run_test_case "META: test framework supports failure reporting" test_test_bootstrap_provides_failure_reporting
run_test_case "META: die imp uses return for word-of-binding" test_die_imp_uses_return_not_exit
run_test_case "META: fail imp returns error code" test_fail_imp_returns_error_code
run_test_case "META: platform detection available" test_platform_detection_available
run_test_case "META: banish spell exists and is executable" test_banish_spell_exists_and_is_executable
run_test_case "META: test-bootstrap checks environment" test_test_bootstrap_checks_environment
run_test_case "PARADIGM: spells do not preload prerequisites" test_spells_do_not_preload_prerequisites
run_test_case "PARADIGM: spells do not source by path" test_spells_do_not_source_by_path

finish_tests
