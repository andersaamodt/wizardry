#!/bin/sh
# Behavioral coverage for wizardry-projects-status.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/wizardry-projects/wizardry-projects-status"

test_wizardry_projects_status_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: wizardry-projects-status" || return 1
}

test_wizardry_projects_status_missing() {
  tmpdir=$(make_tempdir)
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

test_wizardry_projects_status_partial() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/theurgy/spells" "$tmpdir/bin"
  touch "$tmpdir/theurgy/spells/assay-theurgy" "$tmpdir/bin/assay-theurgy"
  chmod +x "$tmpdir/theurgy/spells/assay-theurgy" "$tmpdir/bin/assay-theurgy"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "partial install" || return 1
}

run_test_case "wizardry-projects-status shows help" test_wizardry_projects_status_help
run_test_case "wizardry-projects-status reports missing projects" test_wizardry_projects_status_missing
run_test_case "wizardry-projects-status reports partial install" test_wizardry_projects_status_partial

finish_tests
