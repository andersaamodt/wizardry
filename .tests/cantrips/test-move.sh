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
  _run_spell "spells/cantrips/move" --help
  _assert_success || return 1
  _assert_output_contains "Usage: move" || return 1
}

test_requires_source() {
  _run_spell "spells/cantrips/move"
  _assert_failure || return 1
  _assert_error_contains "source path required" || return 1
}

test_requires_destination() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/move-test.XXXXXX")
  _run_spell "spells/cantrips/move" "$tmpfile"
  rm -f "$tmpfile"
  _assert_failure || return 1
  _assert_error_contains "destination path required" || return 1
}

test_fails_on_missing_source() {
  _run_spell "spells/cantrips/move" "/nonexistent/source" "/tmp/dest"
  _assert_failure || return 1
  _assert_error_contains "source not found" || return 1
}

test_moves_file() {
  tmpdir=$(_make_tempdir)
  src="$tmpdir/source.txt"
  dst="$tmpdir/dest.txt"
  printf "content" > "$src"
  _run_spell "spells/cantrips/move" "$src" "$dst"
  _assert_success || return 1
  [ -f "$dst" ] || { TEST_FAILURE_REASON="destination file not created"; return 1; }
  [ ! -f "$src" ] || { TEST_FAILURE_REASON="source file still exists"; return 1; }
}

_run_test_case "move shows usage text" test_help
_run_test_case "move requires source path" test_requires_source
_run_test_case "move requires destination path" test_requires_destination
_run_test_case "move fails on missing source" test_fails_on_missing_source
_run_test_case "move successfully moves file" test_moves_file

_finish_tests
