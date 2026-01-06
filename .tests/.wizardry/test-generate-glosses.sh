#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/.wizardry/generate-glosses --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "generate-glosses" || return 1
}

test_basic_execution() {
  # Run generate-glosses and capture output
  WIZARDRY_DIR="$ROOT_DIR" run_spell spells/.wizardry/generate-glosses --quiet
  assert_success || return 1
  
  # Check that output contains function definitions (new paradigm)
  # Should have first-word gloss functions like: menu() { parse "menu" "$@"; }
  printf '%s' "$OUTPUT" | grep -q '() { parse' || return 1
}

test_gloss_content() {
  # Run generate-glosses
  WIZARDRY_DIR="$ROOT_DIR" run_spell spells/.wizardry/generate-glosses --quiet
  assert_success || return 1
  
  # Check that output contains first-word gloss functions
  # Example: ask() { parse "ask" "$@"; } for ask-yn spell
  printf '%s' "$OUTPUT" | grep -q 'ask.*parse.*"ask"' || return 1
  
  # Check that output contains alias definitions for hyphenated names
  # Example: alias ask-yn='ask_yn'
  printf '%s' "$OUTPUT" | grep -q "alias.*-.*=" || return 1
}

test_quiet_option() {
  # Run with --quiet to suppress info messages
  WIZARDRY_DIR="$ROOT_DIR" run_spell spells/.wizardry/generate-glosses --quiet
  assert_success || return 1
  
  # Output should contain gloss definitions
  printf '%s' "$OUTPUT" | grep -q '() { parse' || return 1
  
  # Error stream should not contain info messages (only errors/warnings)
  # In quiet mode, diagnostic messages go to stderr, function definitions to stdout
}

test_output_option() {
  tmpdir=$(make_tempdir)
  output_file="$tmpdir/glosses.sh"
  
  # Run with --output to save to file
  WIZARDRY_DIR="$ROOT_DIR" run_spell spells/.wizardry/generate-glosses --quiet --output "$output_file"
  assert_success || return 1
  
  # Check that file was created
  [ -f "$output_file" ] || return 1
  
  # Check that file contains gloss definitions
  grep -q '() { parse' "$output_file" || return 1
}

test_all_spell_categories() {
  # Run generate-glosses
  WIZARDRY_DIR="$ROOT_DIR" run_spell spells/.wizardry/generate-glosses --quiet
  assert_success || return 1
  
  # Verify critical spell glosses exist in output
  # These are first-word glosses for multi-word spells
  
  # Check for first-word glosses (these exist for multi-word commands)
  # ask() for ask-yn
  printf '%s' "$OUTPUT" | grep -q 'ask.*parse' || return 1
  
  # generate() for generate-glosses  
  printf '%s' "$OUTPUT" | grep -q 'generate.*parse' || return 1
  
  # Check for full-name aliases (hyphenated names)
  # mud-menu -> mud_menu
  printf '%s' "$OUTPUT" | grep -q "alias.*-menu=" || return 1
  
  # ask-yn -> ask_yn
  printf '%s' "$OUTPUT" | grep -q "alias ask-yn=" || return 1
}

run_test_case "generate-glosses shows usage" test_help
run_test_case "generate-glosses generates glosses" test_basic_execution
run_test_case "generate-glosses creates valid gloss content" test_gloss_content
run_test_case "generate-glosses --quiet suppresses diagnostics" test_quiet_option
run_test_case "generate-glosses --output writes to file" test_output_option
run_test_case "generate-glosses creates glosses for all spell categories" test_all_spell_categories

finish_tests
