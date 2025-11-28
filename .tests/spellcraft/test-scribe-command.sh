#!/bin/sh
# Tests for scribe-command spell
# - prints usage with --help
# - scribes commands non-interactively with 3+ arguments
# - fails with too few arguments (1-2)
# - creates script file with correct content
# - creates commands file entry

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
  commands_file="$case_dir/commands"
  custom_dir="$case_dir/custom"
  
  SPELLBOOK_COMMANDS_FILE="$commands_file" SPELLBOOK_CUSTOM_DIR="$custom_dir" \
    run_spell "spells/spellcraft/scribe-command" fire spark "echo ignite"
  
  assert_success || return 1
  assert_output_contains "Scribed 'spark' into fire." || return 1
  [ -f "$commands_file" ] || { TEST_FAILURE_REASON="commands file missing"; return 1; }
  [ -x "$custom_dir/spark" ] || { TEST_FAILURE_REASON="custom script missing"; return 1; }
  
  # Check commands file content
  content=$(cat "$commands_file")
  case "$content" in
    *fire*spark*echo\ ignite*) : ;;
    *) TEST_FAILURE_REASON="unexpected command entry: $content"; return 1 ;;
  esac
  
  # Check script content
  script_content=$(cat "$custom_dir/spark")
  case "$script_content" in
    *"echo ignite"*) : ;;
    *) TEST_FAILURE_REASON="script missing command: $script_content"; return 1 ;;
  esac
}

test_fails_with_partial_args() {
  # Only category
  run_spell "spells/spellcraft/scribe-command" fire
  assert_failure || return 1
  case "$ERROR" in
    *"Usage:"*) : ;;
    *) TEST_FAILURE_REASON="expected Usage in stderr"; return 1 ;;
  esac
  
  # Category and name only
  run_spell "spells/spellcraft/scribe-command" fire spark
  assert_failure || return 1
}

test_rejects_invalid_name() {
  case_dir=$(make_tempdir)
  
  # Name with spaces
  SPELLBOOK_COMMANDS_FILE="$case_dir/commands" SPELLBOOK_CUSTOM_DIR="$case_dir/custom" \
    run_spell "spells/spellcraft/scribe-command" fire "spark fire" "echo ignite"
  assert_failure || return 1
  
  # Name starting with dash
  SPELLBOOK_COMMANDS_FILE="$case_dir/commands" SPELLBOOK_CUSTOM_DIR="$case_dir/custom" \
    run_spell "spells/spellcraft/scribe-command" fire "-spark" "echo ignite"
  assert_failure || return 1
}

test_multiword_command() {
  case_dir=$(make_tempdir)
  commands_file="$case_dir/commands"
  custom_dir="$case_dir/custom"
  
  SPELLBOOK_COMMANDS_FILE="$commands_file" SPELLBOOK_CUSTOM_DIR="$custom_dir" \
    run_spell "spells/spellcraft/scribe-command" test test-cmd "echo" "hello" "world"
  
  assert_success || return 1
  content=$(cat "$commands_file")
  case "$content" in
    *echo\ hello\ world*) : ;;
    *) TEST_FAILURE_REASON="multi-word command not joined: $content"; return 1 ;;
  esac
}

run_test_case "scribe-command shows usage" test_shows_help
run_test_case "scribe-command shows usage with -h" test_shows_help_with_h_flag
run_test_case "scribe-command scribes non-interactively" test_noninteractive_scribes_command
run_test_case "scribe-command fails with partial args" test_fails_with_partial_args
run_test_case "scribe-command rejects invalid names" test_rejects_invalid_name
run_test_case "scribe-command joins multi-word commands" test_multiword_command

finish_tests
