#!/bin/sh
# Test coverage for move spell:
# - Shows usage with --help
# - Requires source and destination
# - Fails on missing source

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/cantrips/move" --help
  assert_success || return 1
  assert_output_contains "Usage: move" || return 1
}

test_requires_source() {
  run_spell "spells/cantrips/move"
  assert_failure || return 1
  assert_error_contains "source path required" || return 1
}

test_requires_destination() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/move-test.XXXXXX")
  run_spell "spells/cantrips/move" "$tmpfile"
  rm -f "$tmpfile"
  assert_failure || return 1
  assert_error_contains "destination path required" || return 1
}

test_fails_on_missing_source() {
  run_spell "spells/cantrips/move" "/nonexistent/source" "/tmp/dest"
  assert_failure || return 1
  assert_error_contains "source not found" || return 1
}

test_moves_file() {
  tmpdir=$(make_tempdir)
  src="$tmpdir/source.txt"
  dst="$tmpdir/dest.txt"
  printf "content" > "$src"
  run_spell "spells/cantrips/move" "$src" "$dst"
  assert_success || return 1
  [ -f "$dst" ] || { TEST_FAILURE_REASON="destination file not created"; return 1; }
  [ ! -f "$src" ] || { TEST_FAILURE_REASON="source file still exists"; return 1; }
}

test_moves_file_with_natural_language() {
  tmpdir=$(make_tempdir)
  src="$tmpdir/source.txt"
  dst="$tmpdir/dest.txt"
  printf "content" > "$src"

  run_spell "spells/cantrips/move" from "$src" to "$dst"
  assert_success || return 1
  [ -f "$dst" ] || { TEST_FAILURE_REASON="destination file not created"; return 1; }
  [ ! -f "$src" ] || { TEST_FAILURE_REASON="source file still exists"; return 1; }
}

test_moves_file_named_from() {
  tmpdir=$(make_tempdir)
  src="$tmpdir/from"
  dst="$tmpdir/dest"
  printf "content" > "$src"

  run_cmd env RUN_CMD_WORKDIR="$tmpdir" sh -c "cd \"$tmpdir\" && \"$ROOT_DIR/spells/cantrips/move\" from dest"
  assert_success || return 1
  [ -f "$dst" ] || { TEST_FAILURE_REASON="destination file not created"; return 1; }
  [ ! -f "$src" ] || { TEST_FAILURE_REASON="source file still exists"; return 1; }
}

test_rejects_extra_arguments() {
  tmpdir=$(make_tempdir)
  src="$tmpdir/source.txt"
  dst="$tmpdir/dest.txt"
  printf "content" > "$src"

  run_spell "spells/cantrips/move" "$src" "$dst" extra
  assert_failure || return 1
  assert_error_contains "too many arguments" || return 1
  [ -f "$src" ] || { TEST_FAILURE_REASON="source file should remain after argument error"; return 1; }
  [ ! -f "$dst" ] || { TEST_FAILURE_REASON="destination should not be created after argument error"; return 1; }
}

run_test_case "move shows usage text" test_help
run_test_case "move requires source path" test_requires_source
run_test_case "move requires destination path" test_requires_destination
run_test_case "move fails on missing source" test_fails_on_missing_source
run_test_case "move successfully moves file" test_moves_file
run_test_case "move handles natural language syntax" test_moves_file_with_natural_language
run_test_case "move handles a file named from" test_moves_file_named_from
run_test_case "move rejects extra arguments" test_rejects_extra_arguments

finish_tests
