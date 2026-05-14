#!/bin/sh
# Behavioral coverage for OpenStreetMap arcanum spells.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

arcana_dir="spells/.arcana/openstreetmaps"

test_openstreetmaps_spells_exist_and_are_executable() {
  for spell in \
    install-openstreetmaps \
    uninstall-openstreetmaps \
    is-openstreetmaps-installed \
    openstreetmaps-status \
    openstreetmaps-server-notes \
    openstreetmaps-menu
  do
    target="$arcana_dir/$spell"
    [ -f "$target" ] || {
      TEST_FAILURE_REASON="missing spell: $target"
      return 1
    }
    [ -x "$target" ] || {
      TEST_FAILURE_REASON="spell not executable: $target"
      return 1
    }
  done
}

test_openstreetmaps_help_is_callable() {
  for spell in \
    install-openstreetmaps \
    uninstall-openstreetmaps \
    is-openstreetmaps-installed \
    openstreetmaps-status \
    openstreetmaps-server-notes \
    openstreetmaps-menu
  do
    run_spell "$arcana_dir/$spell" --help
    assert_success || return 1
  done
}

test_openstreetmaps_installed_probe_checks_leaflet_assets() {
  tmp=$(make_tempdir)
  js_root="$tmp/web-js"

  run_cmd env WIZARDRY_WEB_JS_DIR="$js_root" "$ROOT_DIR/$arcana_dir/is-openstreetmaps-installed"
  assert_failure || return 1

  mkdir -p "$js_root/leaflet/images"
  for asset in \
    leaflet.css \
    leaflet.js \
    images/marker-icon.png \
    images/marker-icon-2x.png \
    images/marker-shadow.png
  do
    printf 'asset\n' >"$js_root/leaflet/$asset"
  done

  run_cmd env WIZARDRY_WEB_JS_DIR="$js_root" "$ROOT_DIR/$arcana_dir/is-openstreetmaps-installed"
  assert_success || return 1
}

test_openstreetmaps_status_reports_state() {
  tmp=$(make_tempdir)
  js_root="$tmp/web-js"

  run_cmd env WIZARDRY_WEB_JS_DIR="$js_root" "$ROOT_DIR/$arcana_dir/openstreetmaps-status"
  assert_success || return 1
  assert_output_contains "not installed" || return 1

  mkdir -p "$js_root/leaflet/images"
  for asset in \
    leaflet.css \
    leaflet.js \
    images/marker-icon.png \
    images/marker-icon-2x.png \
    images/marker-shadow.png
  do
    printf 'asset\n' >"$js_root/leaflet/$asset"
  done

  run_cmd env WIZARDRY_WEB_JS_DIR="$js_root" "$ROOT_DIR/$arcana_dir/openstreetmaps-status"
  assert_success || return 1
  assert_output_contains "installed" || return 1
}

test_uninstall_openstreetmaps_removes_leaflet_dir_only() {
  tmp=$(make_tempdir)
  js_root="$tmp/web-js"
  mkdir -p "$js_root/leaflet/images" "$js_root/other"
  printf 'asset\n' >"$js_root/leaflet/leaflet.css"
  printf 'keep\n' >"$js_root/other/keep.txt"

  run_cmd env WIZARDRY_WEB_JS_DIR="$js_root" "$ROOT_DIR/$arcana_dir/uninstall-openstreetmaps"
  assert_success || return 1
  [ ! -e "$js_root/leaflet" ] || {
    TEST_FAILURE_REASON="uninstall-openstreetmaps left leaflet dir behind"
    return 1
  }
  [ -f "$js_root/other/keep.txt" ] || {
    TEST_FAILURE_REASON="uninstall-openstreetmaps removed unrelated shared assets"
    return 1
  }
}

run_test_case "openstreetmaps spells exist and are executable" \
  test_openstreetmaps_spells_exist_and_are_executable
run_test_case "openstreetmaps spell help is callable" test_openstreetmaps_help_is_callable
run_test_case "openstreetmaps installed probe checks Leaflet assets" \
  test_openstreetmaps_installed_probe_checks_leaflet_assets
run_test_case "openstreetmaps status reports state" test_openstreetmaps_status_reports_state
run_test_case "uninstall-openstreetmaps removes only Leaflet dir" \
  test_uninstall_openstreetmaps_removes_leaflet_dir_only

finish_tests
