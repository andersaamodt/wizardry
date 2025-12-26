#!/bin/sh
# Behavioral coverage for evoke-hash:
# - shows usage with --help
# - requires hash argument
# - fails for nonexistent directory
# - fails for non-directory path

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/crypto/evoke-hash" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/crypto/evoke-hash" ]
}

_run_test_case "crypto/evoke-hash is executable" spell_is_executable
_run_test_case "crypto/evoke-hash has content" spell_has_content

shows_help() {
  _run_spell spells/crypto/evoke-hash --help
  _assert_success && _assert_output_contains "Usage: evoke-hash"
}

test_requires_hash_argument() {
  _run_spell spells/crypto/evoke-hash
  _assert_failure && _assert_error_contains "Usage: evoke-hash"
}

test_fails_for_nonexistent_directory() {
  _run_spell spells/crypto/evoke-hash "somehash" "/nonexistent/path"
  _assert_failure && _assert_error_contains "evoke-hash: directory not found"
}

test_fails_for_non_directory() {
  tmpfile=$(_make_tempdir)/testfile
  touch "$tmpfile"
  _run_spell spells/crypto/evoke-hash "somehash" "$tmpfile"
  _assert_failure && _assert_error_contains "evoke-hash: directory not found"
}

_run_test_case "evoke-hash shows help" shows_help
_run_test_case "evoke-hash requires hash argument" test_requires_hash_argument
_run_test_case "evoke-hash fails for nonexistent directory" test_fails_for_nonexistent_directory
_run_test_case "evoke-hash fails for non-directory path" test_fails_for_non_directory

# Test via source-then-invoke pattern  
evoke_hash_help_via_sourcing() {
  _run_sourced_spell evoke-hash --help
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

_run_test_case "evoke-hash works via source-then-invoke" evoke_hash_help_via_sourcing
_finish_tests
