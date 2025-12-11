#!/bin/sh
# Common structural and behavioral checks that apply across all spells and imps.
# Run first as part of test-magic to catch systemic issues early.
#
# This file contains cross-cutting tests that verify properties across the
# entire spellbook. Style/opinionated checks belong in vet-spell instead.
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
  
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
    # Skip declare-globals itself
    # Skip invoke-wizardry - it's sourced into user shell and can't set strict mode
    # Skip word-of-binding - it uses safe patterns (checks ${VAR-} before raw use)
    case "$spell" in
      */.imps/declare-globals|*/.imps/sys/invoke-wizardry|*/.imps/sys/word-of-binding) continue ;;
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
  skip-if-compiled || return $?
  find "$ROOT_DIR/spells" -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) -print | while IFS= read -r spell; do
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
    # Skip declare-globals itself - that's where declarations belong
    # Skip test-bootstrap - WIZARDRY_TMPDIR is a test-local temp directory,
    # not a persistent global exported to user scripts
    # Skip invoke-wizardry - it sets SPELLBOOK_DIR which is a declared global
    case "$spell" in
      */.imps/declare-globals|*/.imps/test/test-bootstrap|*/.imps/sys/invoke-wizardry) continue ;;
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
# Each spell may have show_usage() plus at most a few additional functions.
# The rule enforces linear, readable scrolls over proto-libraries.
# - 0-1 additional functions: freely allowed (the "spell-heart helper")
# - 2 additional functions: warning (invoked from multiple paths, not suitable as imp)
# - 3 additional functions: warning (marginal case)
# - 4+ additional functions: error (proto-library, needs decomposition)
test_spells_follow_function_discipline() {
  tmpfile_2=$(mktemp "${WIZARDRY_TMPDIR}/func-warn-2.XXXXXX")
  tmpfile_3=$(mktemp "${WIZARDRY_TMPDIR}/func-warn-3.XXXXXX")
  tmpfile_4plus=$(mktemp "${WIZARDRY_TMPDIR}/func-viol-4plus.XXXXXX")
  
  find "$ROOT_DIR/spells" -type f -not -path "*/.imps/*" -executable -print | while IFS= read -r spell; do
    name=$(basename "$spell")
    should_skip_file "$name" && continue
    is_posix_shell_script "$spell" || continue
    
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
    
    # Subtract 1 for show_usage (which every spell should have)
    additional_funcs=$((func_count - 1))
    
    # Allow negative (no show_usage is caught by another test)
    [ "$additional_funcs" -lt 0 ] && additional_funcs=0
    
    rel_path=${spell#"$ROOT_DIR/spells/"}
    
    # Write to appropriate temp file based on additional function count
    if [ "$additional_funcs" -ge 4 ]; then
      printf '%s(%s)\n' "$rel_path" "$additional_funcs" >> "$tmpfile_4plus"
    elif [ "$additional_funcs" -eq 3 ]; then
      printf '%s(%s)\n' "$rel_path" "$additional_funcs" >> "$tmpfile_3"
    elif [ "$additional_funcs" -eq 2 ]; then
      printf '%s(%s)\n' "$rel_path" "$additional_funcs" >> "$tmpfile_2"
    fi
  done
  
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

# --- Run all test cases ---

_run_test_case "no duplicate spell names" test_no_duplicate_spell_names
_run_test_case "menu spells require menu command" test_menu_spells_require_menu
_run_test_case "spells have standard help handlers" test_spells_have_help_usage_handlers
_run_test_case "warn about full paths to spells" test_warn_full_paths_to_spells
_run_test_case "test files have matching spells" test_test_files_have_matching_spells
_run_test_case "tests rely only on imps for helpers" test_tests_use_imps_for_helpers
_run_test_case "scripts using declared globals have set -u" test_scripts_using_globals_have_set_u
_run_test_case "declare-globals has exactly 3 globals" test_declare_globals_count
_run_test_case "no undeclared globals exported" test_no_undeclared_global_exports
_run_test_case "no global declarations outside declare-globals" test_no_global_declarations_outside_declare_globals
_run_test_case "no pseudo-globals stored in rc files" test_no_pseudo_globals_in_rc_files
_run_test_case "imps follow one-function-or-zero rule" test_imps_follow_function_rule
_run_test_case "imps have opening comments" test_imps_have_opening_comments
_run_test_case "bootstrap spells have identifying comment" test_bootstrap_spells_identified
_run_test_case "spells follow function discipline" test_spells_follow_function_discipline

_finish_tests
