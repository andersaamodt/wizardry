#!/bin/sh
# Behavioral cases (derived from --help):
# - hash prints usage
# - hash validates arguments before computing
# - hash rejects directories and extra arguments
# - hash emits the resolved path and checksum

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/crypto/hash" --help
  _assert_success || return 1
  _assert_output_contains "Usage: hash" || return 1
  _assert_output_contains "Compute the CRC-32 hash" || return 1
}

hash_requires_single_argument() {
  _run_spell "spells/crypto/hash"
  _assert_failure || return 1
  _assert_error_contains "Usage: hash" || return 1
}

hash_fails_on_missing_file() {
  _run_spell "spells/crypto/hash" "missing.txt"
  _assert_failure || return 1
  _assert_error_contains "Your spell fizzles. There is no file." || return 1
}

hash_rejects_directory() {
  tmpdir=$(_make_tempdir)
  mkdir -p "$tmpdir/dir"

  _run_spell "spells/crypto/hash" "$tmpdir"
  _assert_failure || return 1
  _assert_error_contains "Your spell fizzles. There is no file." || return 1
}

hash_rejects_extra_arguments() {
  file="$WIZARDRY_TMPDIR/hash_extra.txt"
  printf 'extra' >"$file"

  _run_spell "spells/crypto/hash" "$file" another
  _assert_failure || return 1
  _assert_error_contains "Usage: hash" || return 1
}

hash_reports_path_and_checksum() {
  tmpdir=$(_make_tempdir)
  cp "spells/crypto/hash" "$tmpdir/hash"
  sample_path="$tmpdir/sample.txt"
  printf 'hash me' >"$sample_path"
  checksum=$(cksum "$sample_path" | awk '{print $1}')

  _run_cmd "$tmpdir/hash" "sample.txt"
  _assert_success || return 1
  # Normalize path for macOS compatibility (TMPDIR ends with /)
  normalized_path=$(printf '%s' "$sample_path" | sed 's|//|/|g')
  expected_output=$(printf '%s\n0x%x\n' "$normalized_path" "$checksum")
  [ "$OUTPUT" = "$expected_output" ] || {
    TEST_FAILURE_REASON="hash output did not match expected path and checksum"
    return 1
  }
}

_run_test_case "hash prints usage" test_help
_run_test_case "hash requires exactly one argument" hash_requires_single_argument
_run_test_case "hash fails when the file is missing" hash_fails_on_missing_file
_run_test_case "hash fails when given a directory" hash_rejects_directory
_run_test_case "hash rejects extra arguments" hash_rejects_extra_arguments
_run_test_case "hash reports the resolved path and checksum" hash_reports_path_and_checksum


# Test via source-then-invoke pattern  
hash_help_via_sourcing() {
  _run_sourced_spell hash --help
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

_run_test_case "hash works via source-then-invoke" hash_help_via_sourcing
_finish_tests
