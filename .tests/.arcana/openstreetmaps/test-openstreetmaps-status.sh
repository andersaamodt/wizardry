#!/bin/sh
# Behavioral coverage for openstreetmaps-status.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/openstreetmaps/openstreetmaps-status"

test_openstreetmaps_status_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: openstreetmaps-status" || return 1
}

test_openstreetmaps_status_reports_not_installed() {
  tmpdir=$(make_tempdir)
  run_cmd env HOME="$tmpdir/home" WIZARDRY_WEB_JS_DIR="$tmpdir/js" sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "not installed" || return 1
}

test_openstreetmaps_status_reports_installed() {
  tmpdir=$(make_tempdir)
  install_root="$tmpdir/js"
  mkdir -p "$install_root/leaflet/images"
  for asset in leaflet.css leaflet.js images/marker-icon.png images/marker-icon-2x.png images/marker-shadow.png; do
    printf 'asset\n' > "$install_root/leaflet/$asset"
  done

  run_cmd env HOME="$tmpdir/home" WIZARDRY_WEB_JS_DIR="$install_root" sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "installed" || return 1
}

run_test_case "openstreetmaps-status shows help" test_openstreetmaps_status_help
run_test_case "openstreetmaps-status reports not installed" \
  test_openstreetmaps_status_reports_not_installed
run_test_case "openstreetmaps-status reports installed" \
  test_openstreetmaps_status_reports_installed

finish_tests
