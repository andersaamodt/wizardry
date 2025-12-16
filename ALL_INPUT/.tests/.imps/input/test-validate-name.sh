#!/bin/sh
# Test validate-name imp

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_valid_names() {
  _run_cmd validate-name "myspell" "spell"
  _assert_success || return 1
  
  _run_cmd validate-name "my-spell" "spell"
  _assert_success || return 1
  
  _run_cmd validate-name "my_spell" "spell"
  _assert_success || return 1
  
  _run_cmd validate-name "my.spell" "spell"
  _assert_success || return 1
  
  _run_cmd validate-name "MySpell123" "spell"
  _assert_success || return 1
}

test_invalid_names_with_spaces() {
  _run_cmd validate-name "my spell" "spell"
  _assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"may contain only"*"no spaces"*) : ;;
    *) TEST_FAILURE_REASON="expected error about spaces"; return 1 ;;
  esac
}

test_invalid_names_with_special_chars() {
  _run_cmd validate-name "my@spell" "spell"
  _assert_failure || return 1
  
  _run_cmd validate-name "my spell!" "spell"
  _assert_failure || return 1
}

test_invalid_names_starting_with_dash() {
  _run_cmd validate-name "-myspell" "spell"
  _assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"may not begin with a dash"*) : ;;
    *) TEST_FAILURE_REASON="expected error about leading dash"; return 1 ;;
  esac
}

test_empty_name() {
  _run_cmd validate-name "" "spell"
  _assert_failure || return 1
}

test_context_in_error_message() {
  _run_cmd validate-name "my spell" "category"
  _assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"categorys"*|*"category"*) : ;;
    *) TEST_FAILURE_REASON="expected context 'category' in error"; return 1 ;;
  esac
}

_run_test_case "validate-name accepts valid names" test_valid_names
_run_test_case "validate-name rejects names with spaces" test_invalid_names_with_spaces
_run_test_case "validate-name rejects special characters" test_invalid_names_with_special_chars
_run_test_case "validate-name rejects leading dash" test_invalid_names_starting_with_dash
_run_test_case "validate-name rejects empty name" test_empty_name
_run_test_case "validate-name includes context in error" test_context_in_error_message

_finish_tests
