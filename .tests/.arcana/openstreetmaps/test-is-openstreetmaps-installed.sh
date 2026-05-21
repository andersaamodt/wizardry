#!/bin/sh
# Behavioral coverage for is-openstreetmaps-installed.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/openstreetmaps/is-openstreetmaps-installed"

test_is_openstreetmaps_installed_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: is-openstreetmaps-installed" || return 1
}

test_is_openstreetmaps_installed_fails_without_assets() {
  tmpdir=$(make_tempdir)
  run_cmd env HOME="$tmpdir/home" WIZARDRY_WEB_JS_DIR="$tmpdir/js" sh "$ROOT_DIR/$target"
  assert_failure || return 1
}

test_is_openstreetmaps_installed_succeeds_with_assets() {
  tmpdir=$(make_tempdir)
  install_root="$tmpdir/js"
  mkdir -p "$install_root/leaflet/images"
  for asset in leaflet.css leaflet.js images/marker-icon.png images/marker-icon-2x.png images/marker-shadow.png; do
    printf 'asset\n' > "$install_root/leaflet/$asset"
  done

  run_cmd env HOME="$tmpdir/home" WIZARDRY_WEB_JS_DIR="$install_root" sh "$ROOT_DIR/$target"
  assert_success || return 1
}

run_test_case "is-openstreetmaps-installed shows help" test_is_openstreetmaps_installed_help
run_test_case "is-openstreetmaps-installed fails without assets" \
  test_is_openstreetmaps_installed_fails_without_assets
run_test_case "is-openstreetmaps-installed succeeds with assets" \
  test_is_openstreetmaps_installed_succeeds_with_assets

finish_tests
