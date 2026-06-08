#!/bin/sh
# Behavioral coverage for theurgy-menu.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/theurgy/theurgy-menu"

test_theurgy_menu_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: theurgy-menu" || return 1
}

test_theurgy_menu_falls_back_without_menu() {
  tmpdir=$(make_tempdir)
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    PATH="/usr/bin:/bin:/usr/sbin:/sbin" sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

test_theurgy_menu_reports_installed_without_menu() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/theurgy/spells" "$tmpdir/bin"
  touch "$tmpdir/theurgy/spells/assay-theurgy" "$tmpdir/bin/assay-theurgy"
  chmod +x "$tmpdir/theurgy/spells/assay-theurgy" "$tmpdir/bin/assay-theurgy"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    PATH="/usr/bin:/bin:/usr/sbin:/sbin" sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "installed" || return 1
}

run_test_case "theurgy-menu shows help" test_theurgy_menu_help
run_test_case "theurgy-menu falls back without menu" test_theurgy_menu_falls_back_without_menu
run_test_case "theurgy-menu reports installed fallback" test_theurgy_menu_reports_installed_without_menu

finish_tests
