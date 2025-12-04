#!/bin/sh
# Behavioral coverage for forget:
# - prints usage
# - rejects unknown options
# - removes a spell from the cast menu
# - fails when spell name is missing
# - fails when spell is not memorized

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

cast_env() {
  dir=$(mktemp -d "${WIZARDRY_TMPDIR}/cast.XXXXXX")
  mkdir -p "$dir"
  printf 'WIZARDRY_CAST_DIR=%s' "$dir"
}

run_memorize() {
  env_var=$1
  shift
  run_cmd env "$env_var" "$ROOT_DIR/spells/cantrips/memorize" "$@"
}

run_forget() {
  env_var=$1
  shift
  run_cmd env "$env_var" "$ROOT_DIR/spells/spellcraft/forget" "$@"
}

test_help() {
  run_spell "spells/spellcraft/forget" --help
  assert_success && assert_output_contains "Usage:"
}

test_forget_removes_spell() {
  env_var=$(cast_env)
  # First memorize a spell
  run_memorize "$env_var" myspell
  assert_success
  
  # Verify it's memorized
  run_memorize "$env_var" list
  assert_output_contains "myspell"
  
  # Now forget it
  run_forget "$env_var" myspell
  assert_success
  
  # Verify it's gone
  run_memorize "$env_var" list
  case "$OUTPUT" in
    *myspell*) TEST_FAILURE_REASON="spell should have been forgotten"; return 1 ;;
    *) : ;;
  esac
}

test_forget_requires_name() {
  run_spell "spells/spellcraft/forget"
  assert_failure && assert_error_contains "spell name required"
}

test_forget_fails_when_not_memorized() {
  env_var=$(cast_env)
  run_forget "$env_var" nonexistent
  assert_failure && assert_error_contains "not memorized"
}

test_unknown_option() {
  run_spell "spells/spellcraft/forget" --unknown
  assert_failure && assert_error_contains "unknown option"
}

run_test_case "forget prints usage" test_help
run_test_case "forget rejects unknown option" test_unknown_option
run_test_case "forget removes spell from cast menu" test_forget_removes_spell
run_test_case "forget requires spell name" test_forget_requires_name
run_test_case "forget fails when spell not memorized" test_forget_fails_when_not_memorized

finish_tests
