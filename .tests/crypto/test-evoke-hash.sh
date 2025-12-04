#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/crypto/evoke-hash" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/crypto/evoke-hash" ]
}

shows_help() {
  run_spell spells/crypto/evoke-hash --help
  assert_success
  assert_output_contains "Usage:"
}

finds_matching_file() {
  tmpdir=$(mktemp -d "$WIZARDRY_TMPDIR/evoke.XXXXXX")
  logdir="$tmpdir/bin"
  mkdir -p "$logdir"

  cat >"$logdir/read-magic" <<'SH'
#!/bin/sh
cat "$1"
SH
  chmod +x "$logdir/read-magic"

  printf 'hash123' >"$tmpdir/one.txt"
  printf 'different' >"$tmpdir/two.txt"

  PATH="$logdir:$PATH" run_spell spells/crypto/evoke-hash hash123 "$tmpdir"
  assert_success
  assert_output_contains "one.txt"
}

fails_when_missing_directory() {
  run_spell spells/crypto/evoke-hash missing /nonexistent
  assert_failure
  assert_error_contains "is not a directory"
}

run_test_case "crypto/evoke-hash is executable" spell_is_executable
run_test_case "crypto/evoke-hash has content" spell_has_content
run_test_case "evoke-hash shows help" shows_help
run_test_case "evoke-hash finds matching files" finds_matching_file
run_test_case "evoke-hash rejects missing directories" fails_when_missing_directory

finish_tests
