#!/bin/sh
# Behavioral coverage for is-theurgy-installed.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/theurgy/is-theurgy-installed"

test_is_theurgy_installed_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: is-theurgy-installed" || return 1
}

test_is_theurgy_installed_fails_when_missing() {
  tmpdir=$(make_tempdir)
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    sh "$ROOT_DIR/$target"
  assert_failure || return 1
}

test_is_theurgy_installed_succeeds_when_wrapped() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/theurgy/spells" "$tmpdir/bin"
  touch "$tmpdir/theurgy/spells/assay-theurgy" "$tmpdir/bin/assay-theurgy"
  chmod +x "$tmpdir/theurgy/spells/assay-theurgy" "$tmpdir/bin/assay-theurgy"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
}

run_test_case "is-theurgy-installed shows help" test_is_theurgy_installed_help
run_test_case "is-theurgy-installed fails when missing" test_is_theurgy_installed_fails_when_missing
run_test_case "is-theurgy-installed succeeds when wrapper exists" test_is_theurgy_installed_succeeds_when_wrapped

finish_tests
