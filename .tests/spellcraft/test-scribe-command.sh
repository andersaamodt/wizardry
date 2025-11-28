#!/bin/sh
# Tests for scribe-command spell
# - prints usage with --help
# - scribes commands non-interactively with 2+ arguments (NAME COMMAND)
# - fails with only 1 argument (needs name and command)
# - creates script file with correct content in ~/.spellbook
# - rejects names with spaces

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_shows_help() {
  run_spell "spells/spellcraft/scribe-command" --help
  assert_success && assert_output_contains "Usage:"
}

test_shows_help_with_h_flag() {
  run_spell "spells/spellcraft/scribe-command" -h
  assert_success && assert_output_contains "Usage:"
}

test_noninteractive_scribes_command() {
  case_dir=$(make_tempdir)
  
  WIZARDRY_SPELL_HOME="$case_dir" \
    run_spell "spells/spellcraft/scribe-command" spark "echo ignite"
  
  assert_success || return 1
  assert_output_contains "Scribed 'spark' to" || return 1
  [ -x "$case_dir/spark" ] || { TEST_FAILURE_REASON="script missing at $case_dir/spark"; return 1; }
  
  # Check script content
  script_content=$(cat "$case_dir/spark")
  case "$script_content" in
    *"echo ignite"*) : ;;
    *) TEST_FAILURE_REASON="script missing command: $script_content"; return 1 ;;
  esac
}

test_fails_with_partial_args() {
  # Only name (needs name and command)
  run_spell "spells/spellcraft/scribe-command" spark
  assert_failure || return 1
  case "$ERROR" in
    *"Usage:"*) : ;;
    *) TEST_FAILURE_REASON="expected Usage in stderr"; return 1 ;;
  esac
}

test_rejects_invalid_name() {
  case_dir=$(make_tempdir)
  
  # Name with spaces
  WIZARDRY_SPELL_HOME="$case_dir" \
    run_spell "spells/spellcraft/scribe-command" "spark fire" "echo ignite"
  assert_failure || return 1
  
  # Name starting with dash
  WIZARDRY_SPELL_HOME="$case_dir" \
    run_spell "spells/spellcraft/scribe-command" "-spark" "echo ignite"
  assert_failure || return 1
}

test_multiword_command() {
  case_dir=$(make_tempdir)
  
  WIZARDRY_SPELL_HOME="$case_dir" \
    run_spell "spells/spellcraft/scribe-command" test-cmd "echo" "hello" "world"
  
  assert_success || return 1
  [ -x "$case_dir/test-cmd" ] || { TEST_FAILURE_REASON="script missing"; return 1; }
  
  # Check script content contains joined command
  script_content=$(cat "$case_dir/test-cmd")
  case "$script_content" in
    *"echo hello world"*) : ;;
    *) TEST_FAILURE_REASON="multi-word command not joined: $script_content"; return 1 ;;
  esac
}

test_script_is_executable() {
  case_dir=$(make_tempdir)
  
  WIZARDRY_SPELL_HOME="$case_dir" \
    run_spell "spells/spellcraft/scribe-command" myspell "echo hello"
  
  assert_success || return 1
  [ -x "$case_dir/myspell" ] || { TEST_FAILURE_REASON="script not executable"; return 1; }
  
  # Run the script and check output
  output=$("$case_dir/myspell")
  case "$output" in
    *hello*) : ;;
    *) TEST_FAILURE_REASON="script did not execute correctly: $output"; return 1 ;;
  esac
}

run_test_case "scribe-command shows usage" test_shows_help
run_test_case "scribe-command shows usage with -h" test_shows_help_with_h_flag
run_test_case "scribe-command scribes non-interactively" test_noninteractive_scribes_command
run_test_case "scribe-command fails with partial args" test_fails_with_partial_args
run_test_case "scribe-command rejects invalid names" test_rejects_invalid_name
run_test_case "scribe-command joins multi-word commands" test_multiword_command
run_test_case "scribe-command creates executable scripts" test_script_is_executable

finish_tests
