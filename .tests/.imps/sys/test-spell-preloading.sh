#!/bin/sh
# Test that spells are pre-loaded via invoke-wizardry (word-of-binding paradigm)

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: menu function is available immediately after sourcing invoke-wizardry
test_menu_preloaded() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-menu-preloaded.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Source invoke-wizardry
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Check if menu is available as a command (should be pre-loaded function)
if command -v menu >/dev/null 2>&1; then
  printf 'menu command available\n'
  # Check if it's a function or alias
  menu_type=\$(type menu 2>/dev/null | head -1)
  case "\$menu_type" in
    *function*|*alias*) printf 'menu is pre-loaded\n'; exit 0 ;;
    *) printf 'menu type: %s\n' "\$menu_type"; exit 0 ;;
  esac
else
  printf 'menu not found\n'
  exit 1
fi
EOF
  chmod +x "$tmpdir/test-menu-preloaded.sh"
  
  _run_cmd sh "$tmpdir/test-menu-preloaded.sh"
  _assert_success || return 1
  _assert_output_contains "menu command available" || return 1
  _assert_output_contains "menu is pre-loaded" || return 1
}

# Test: Spell directories are NOT added to PATH by invoke-wizardry (new paradigm)
test_spell_dirs_not_added_to_path() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-no-spell-path.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Start with a minimal PATH (no wizardry)
PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

# Source invoke-wizardry
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Check that spell directories were NOT added to PATH
case ":\${PATH}:" in
  *":$ROOT_DIR/spells/cantrips:"*)
    printf 'ERROR: cantrips directory added to PATH (old antipattern)\n'
    exit 1
    ;;
  *":$ROOT_DIR/spells/menu:"*)
    printf 'ERROR: menu directory added to PATH (old antipattern)\n'
    exit 1
    ;;
  *":$ROOT_DIR/spells/arcane:"*)
    printf 'ERROR: arcane directory added to PATH (old antipattern)\n'
    exit 1
    ;;
esac

printf 'spell directories not added to PATH by invoke-wizardry (correct)\n'
exit 0
EOF
  chmod +x "$tmpdir/test-no-spell-path.sh"
  
  _run_cmd sh "$tmpdir/test-no-spell-path.sh"
  _assert_success || return 1
  _assert_output_contains "spell directories not added to PATH" || return 1
}

# Test: Imps are NOT added to PATH (word-of-binding paradigm)
test_imps_not_added_to_path() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-imps-path.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Start with minimal PATH
PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

# Source invoke-wizardry
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Check that imp directories were NOT added to PATH
case ":\${PATH}:" in
  *":$ROOT_DIR/spells/.imps/out:"*)
    printf 'ERROR: imp directory added to PATH (old antipattern)\n'
    exit 1
    ;;
  *":$ROOT_DIR/spells/.imps/cond:"*)
    printf 'ERROR: imp directory added to PATH (old antipattern)\n'
    exit 1
    ;;
esac

printf 'imp directories not added to PATH (correct)\n'
exit 0
EOF
  chmod +x "$tmpdir/test-imps-path.sh"
  
  _run_cmd sh "$tmpdir/test-imps-path.sh"
  _assert_success || return 1
  _assert_output_contains "imp directories not added to PATH (correct)" || return 1
}

# Test: Imps are still available as commands (pre-loaded)
test_imps_preloaded() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-imps-available.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Source invoke-wizardry
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Check that common imps are available even though not in PATH
preloaded_count=0

for imp_cmd in say has warn die; do
  if command -v "\$imp_cmd" >/dev/null 2>&1; then
    preloaded_count=\$((preloaded_count + 1))
  fi
done

if [ "\$preloaded_count" -ge 3 ]; then
  printf '%d imps pre-loaded and available\n' "\$preloaded_count"
  exit 0
else
  printf 'ERROR: only %d imps pre-loaded (expected at least 3)\n' "\$preloaded_count"
  exit 1
fi
EOF
  chmod +x "$tmpdir/test-imps-available.sh"
  
  _run_cmd sh "$tmpdir/test-imps-available.sh"
  _assert_success || return 1
  _assert_output_contains "imps pre-loaded and available" || return 1
}

# Test: Multiple common spells are pre-loaded
test_multiple_spells_preloaded() {
  tmpdir=$(_make_tempdir)
  
  cat > "$tmpdir/test-multiple-spells.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR

# Source invoke-wizardry
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null

# Check for several common spell functions
preloaded_count=0

for spell_cmd in menu main-menu ask-yn; do
  if command -v "\$spell_cmd" >/dev/null 2>&1; then
    preloaded_count=\$((preloaded_count + 1))
  fi
done

if [ "\$preloaded_count" -gt 0 ]; then
  printf '%d spells pre-loaded\n' "\$preloaded_count"
  exit 0
else
  printf 'ERROR: no spells pre-loaded\n'
  exit 1
fi
EOF
  chmod +x "$tmpdir/test-multiple-spells.sh"
  
  _run_cmd sh "$tmpdir/test-multiple-spells.sh"
  _assert_success || return 1
  _assert_output_contains "spells pre-loaded" || return 1
}

_run_test_case "menu is pre-loaded as function" test_menu_preloaded
_run_test_case "spell directories not added to PATH by invoke-wizardry" test_spell_dirs_not_added_to_path
_run_test_case "imp directories not added to PATH" test_imps_not_added_to_path
_run_test_case "imps are pre-loaded and available" test_imps_preloaded
_run_test_case "multiple common spells pre-loaded" test_multiple_spells_preloaded

_finish_tests
