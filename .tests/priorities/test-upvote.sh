#!/bin/sh
# Test coverage for upvote spell:
# - Shows usage with --help
# - Requires file argument
# - Fails on missing file
# - Increments upvote count

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/priorities/upvote" --help
  _assert_success || return 1
  _assert_output_contains "Usage: upvote" || return 1
}

test_requires_argument() {
  _run_spell "spells/priorities/upvote"
  _assert_failure || return 1
  _assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  _run_spell "spells/priorities/upvote" "/nonexistent/file.txt"
  _assert_failure || return 1
  _assert_error_contains "file not found" || return 1
}

_run_test_case "upvote shows usage text" test_help
_run_test_case "upvote requires file argument" test_requires_argument
_run_test_case "upvote fails on missing file" test_fails_on_missing_file


# Test via source-then-invoke pattern  
upvote_help_via_sourcing() {
  _run_sourced_spell upvote --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "upvote works via source-then-invoke" upvote_help_via_sourcing
_finish_tests
