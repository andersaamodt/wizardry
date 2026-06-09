#!/bin/sh
# Behavioral coverage for check-theurgy.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/theurgy/check-theurgy"

test_check_theurgy_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: check-theurgy" || return 1
}

test_check_theurgy_reports_missing() {
  tmpdir=$(make_tempdir)
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "status=bad" || return 1
}

test_check_theurgy_reports_installed() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/theurgy/spells" "$tmpdir/bin"
  touch "$tmpdir/theurgy/spells/assay-theurgy" "$tmpdir/bin/assay-theurgy"
  chmod +x "$tmpdir/theurgy/spells/assay-theurgy" "$tmpdir/bin/assay-theurgy"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "status=ok" || return 1
}

run_test_case "check-theurgy shows help" test_check_theurgy_help
run_test_case "check-theurgy reports missing install" test_check_theurgy_reports_missing
run_test_case "check-theurgy reports installed state" test_check_theurgy_reports_installed

finish_tests
