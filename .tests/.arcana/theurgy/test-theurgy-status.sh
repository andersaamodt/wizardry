#!/bin/sh
# Behavioral coverage for theurgy-status.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/theurgy/theurgy-status"

test_theurgy_status_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: theurgy-status" || return 1
}

test_theurgy_status_missing() {
  tmpdir=$(make_tempdir)
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

test_theurgy_status_installed() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/theurgy/spells" "$tmpdir/bin"
  touch "$tmpdir/theurgy/spells/assay-theurgy" "$tmpdir/bin/assay-theurgy"
  chmod +x "$tmpdir/theurgy/spells/assay-theurgy" "$tmpdir/bin/assay-theurgy"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  [ "$OUTPUT" = "installed" ] || {
    TEST_FAILURE_REASON="expected installed status, got: $OUTPUT"
    return 1
  }
}

run_test_case "theurgy-status shows help" test_theurgy_status_help
run_test_case "theurgy-status reports missing install" test_theurgy_status_missing
run_test_case "theurgy-status reports installed state" test_theurgy_status_installed

finish_tests
