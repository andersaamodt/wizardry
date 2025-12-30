#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_sourced_spell generate-glosses --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "generate-glosses" || return 1
}

test_basic_execution() {
  tmpdir=$(make_tempdir)
  spellbook_dir="$tmpdir/.spellbook"
  glossary_dir="$spellbook_dir/.glossary"
  
  # Create spellbook directory
  mkdir -p "$spellbook_dir" || return 1
  
  # Run generate-glosses
  SPELLBOOK_DIR="$spellbook_dir" WIZARDRY_DIR="$ROOT_DIR" run_sourced_spell generate-glosses --quiet
  assert_success || return 1
  
  # Check that glossary directory was created
  [ -d "$glossary_dir" ] || return 1
  
  # Check that some glosses were generated
  # Use -perm /111 for cross-platform compatibility (BSD find on older macOS)
  gloss_count=$(find "$glossary_dir" -type f -perm /111 2>/dev/null | wc -l | tr -d ' ')
  [ "$gloss_count" -gt 0 ] || return 1
}

test_gloss_content() {
  tmpdir=$(make_tempdir)
  spellbook_dir="$tmpdir/.spellbook"
  glossary_dir="$spellbook_dir/.glossary"
  
  # Create spellbook directory
  mkdir -p "$spellbook_dir" || return 1
  
  # Run generate-glosses
  SPELLBOOK_DIR="$spellbook_dir" WIZARDRY_DIR="$ROOT_DIR" run_sourced_spell generate-glosses --quiet
  assert_success || return 1
  
  # Check that menu gloss exists and has correct content
  menu_gloss="$glossary_dir/menu"
  [ -f "$menu_gloss" ] || return 1
  [ -x "$menu_gloss" ] || return 1
  
  # Verify gloss contains exec parse command
  grep -q 'exec parse "menu"' "$menu_gloss" || return 1
}

test_force_regeneration() {
  tmpdir=$(make_tempdir)
  spellbook_dir="$tmpdir/.spellbook"
  glossary_dir="$spellbook_dir/.glossary"
  
  # Create spellbook directory
  mkdir -p "$spellbook_dir" || return 1
  
  # Generate glosses first time
  SPELLBOOK_DIR="$spellbook_dir" WIZARDRY_DIR="$ROOT_DIR" run_sourced_spell generate-glosses --quiet
  assert_success || return 1
  
  # Generate again with --force
  SPELLBOOK_DIR="$spellbook_dir" WIZARDRY_DIR="$ROOT_DIR" run_sourced_spell generate-glosses --force --quiet
  assert_success || return 1
}

test_synonym_generation() {
  tmpdir=$(make_tempdir)
  spellbook_dir="$tmpdir/.spellbook"
  glossary_dir="$spellbook_dir/.glossary"
  
  # Create spellbook directory and synonym file
  mkdir -p "$spellbook_dir" || return 1
  cat > "$spellbook_dir/.synonyms" << 'EOF'
# Test synonyms
alias ll='ls -la'
alias jump='jump-to-marker'
EOF
  
  # Run generate-glosses
  SPELLBOOK_DIR="$spellbook_dir" WIZARDRY_DIR="$ROOT_DIR" run_sourced_spell generate-glosses --quiet
  assert_success || return 1
  
  # Check that synonym glosses were created
  [ -f "$glossary_dir/ll" ] || return 1
  [ -f "$glossary_dir/jump" ] || return 1
  
  # Verify ll gloss has correct target
  grep -q 'exec parse "ls -la"' "$glossary_dir/ll" || return 1
  
  # Verify jump gloss has correct target
  grep -q 'exec parse "jump-to-marker"' "$glossary_dir/jump" || return 1
}

test_all_spell_categories() {
  tmpdir=$(make_tempdir)
  spellbook_dir="$tmpdir/.spellbook"
  glossary_dir="$spellbook_dir/.glossary"
  
  # Create spellbook directory
  mkdir -p "$spellbook_dir" || return 1
  
  # Run generate-glosses
  SPELLBOOK_DIR="$spellbook_dir" WIZARDRY_DIR="$ROOT_DIR" run_sourced_spell generate-glosses --quiet
  assert_success || return 1
  
  # Verify critical spell glosses exist from different categories
  # Menu category
  [ -f "$glossary_dir/menu" ] || return 1
  [ -f "$glossary_dir/main-menu" ] || return 1
  
  # Cantrips
  [ -f "$glossary_dir/ask-yn" ] || return 1
  
  # Arcane
  [ -f "$glossary_dir/forall" ] || return 1
  [ -f "$glossary_dir/copy" ] || return 1
  
  # System
  [ -f "$glossary_dir/generate-glosses" ] || return 1
  
  # Imps should also have glosses
  [ -f "$glossary_dir/has" ] || return 1
  [ -f "$glossary_dir/say" ] || return 1
}

run_test_case "generate-glosses shows usage" test_help
run_test_case "generate-glosses generates glosses" test_basic_execution
run_test_case "generate-glosses creates valid gloss content" test_gloss_content
run_test_case "generate-glosses --force regenerates" test_force_regeneration
run_test_case "generate-glosses creates synonym glosses" test_synonym_generation
run_test_case "generate-glosses creates glosses for all spell categories" test_all_spell_categories

finish_tests
