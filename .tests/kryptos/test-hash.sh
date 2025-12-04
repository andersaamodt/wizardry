#!/bin/sh
# Behavioral cases (derived from --help):
# - hash prints usage
# - hash validates arguments before computing
# - hash rejects directories and extra arguments
# - hash emits the resolved path and checksum

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/kryptos/hash" --help
  assert_success || return 1
  assert_output_contains "Usage: hash" || return 1
  assert_output_contains "Compute the CRC-32 hash" || return 1
}

hash_requires_single_argument() {
  run_spell "spells/kryptos/hash"
  assert_failure || return 1
  assert_output_contains "Usage: hash" || return 1
}

hash_fails_on_missing_file() {
  run_spell "spells/kryptos/hash" "missing.txt"
  assert_failure || return 1
  assert_output_contains "Your spell fizzles. There is no file." || return 1
}

hash_rejects_directory() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/dir"

  run_spell "spells/kryptos/hash" "$tmpdir"
  assert_failure || return 1
  assert_output_contains "Your spell fizzles. There is no file." || return 1
}

hash_rejects_extra_arguments() {
  file="$WIZARDRY_TMPDIR/hash_extra.txt"
  printf 'extra' >"$file"

  run_spell "spells/kryptos/hash" "$file" another
  assert_failure || return 1
  assert_output_contains "Usage: hash" || return 1
}

hash_reports_path_and_checksum() {
  tmpdir=$(make_tempdir)
  cp "spells/kryptos/hash" "$tmpdir/hash"
  sample_path="$tmpdir/sample.txt"
  printf 'hash me' >"$sample_path"
  checksum=$(cksum "$sample_path" | awk '{print $1}')

  run_cmd "$tmpdir/hash" "sample.txt"
  assert_success || return 1
  # Normalize path for macOS compatibility (TMPDIR ends with /)
  normalized_path=$(printf '%s' "$sample_path" | sed 's|//|/|g')
  expected_output=$(printf '%s\n0x%x\n' "$normalized_path" "$checksum")
  [ "$OUTPUT" = "$expected_output" ] || {
    TEST_FAILURE_REASON="hash output did not match expected path and checksum"
    return 1
  }
}

run_test_case "hash prints usage" test_help
run_test_case "hash requires exactly one argument" hash_requires_single_argument
run_test_case "hash fails when the file is missing" hash_fails_on_missing_file
run_test_case "hash fails when given a directory" hash_rejects_directory
run_test_case "hash rejects extra arguments" hash_rejects_extra_arguments
run_test_case "hash reports the resolved path and checksum" hash_reports_path_and_checksum

finish_tests
