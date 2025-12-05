#!/bin/sh
# Behavioral coverage for evoke-hash:
# - shows usage with --help
# - requires hash argument
# - fails for nonexistent directory
# - fails for non-directory path

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/crypto/evoke-hash" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/crypto/evoke-hash" ]
}

run_test_case "crypto/evoke-hash is executable" spell_is_executable
run_test_case "crypto/evoke-hash has content" spell_has_content

shows_help() {
  run_spell spells/crypto/evoke-hash --help
  assert_success && assert_output_contains "Usage: evoke-hash"
}

test_requires_hash_argument() {
  run_spell spells/crypto/evoke-hash
  assert_failure && assert_error_contains "Usage: evoke-hash"
}

test_fails_for_nonexistent_directory() {
  run_spell spells/crypto/evoke-hash "somehash" "/nonexistent/path"
  assert_failure && assert_error_contains "is not a directory"
}

test_fails_for_non_directory() {
  tmpfile=$(make_tempdir)/testfile
  touch "$tmpfile"
  run_spell spells/crypto/evoke-hash "somehash" "$tmpfile"
  assert_failure && assert_error_contains "is not a directory"
}

run_test_case "evoke-hash shows help" shows_help
run_test_case "evoke-hash requires hash argument" test_requires_hash_argument
run_test_case "evoke-hash fails for nonexistent directory" test_fails_for_nonexistent_directory
run_test_case "evoke-hash fails for non-directory path" test_fails_for_non_directory
finish_tests
