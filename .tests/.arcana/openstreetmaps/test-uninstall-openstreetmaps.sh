#!/bin/sh
# Behavioral coverage for uninstall-openstreetmaps.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/openstreetmaps/uninstall-openstreetmaps"

test_uninstall_openstreetmaps_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: uninstall-openstreetmaps" || return 1
}

test_uninstall_openstreetmaps_rejects_unsafe_install_path() {
  tmpdir=$(make_tempdir)
  run_cmd env \
    HOME="$tmpdir/home" \
    WIZARDRY_WEB_JS_DIR="$tmpdir/../bad" \
    PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" \
    WIZARDRY_DIR="$ROOT_DIR" \
    sh "$ROOT_DIR/$target"
  assert_failure || return 1
  assert_error_contains "refusing unsafe install path" || return 1
}

test_uninstall_openstreetmaps_removes_leaflet_dir_only() {
  tmpdir=$(make_tempdir)
  install_root="$tmpdir/js"
  mkdir -p "$install_root/leaflet/images" "$install_root/other"
  printf 'asset\n' > "$install_root/leaflet/leaflet.css"
  printf 'keep\n' > "$install_root/other/keep.txt"

  run_cmd env \
    HOME="$tmpdir/home" \
    WIZARDRY_WEB_JS_DIR="$install_root" \
    PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" \
    WIZARDRY_DIR="$ROOT_DIR" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  [ ! -e "$install_root/leaflet" ] || {
    TEST_FAILURE_REASON="uninstall-openstreetmaps left leaflet assets behind"
    return 1
  }
  [ -f "$install_root/other/keep.txt" ] || {
    TEST_FAILURE_REASON="uninstall-openstreetmaps removed unrelated files"
    return 1
  }
}

run_test_case "uninstall-openstreetmaps shows help" test_uninstall_openstreetmaps_help
run_test_case "uninstall-openstreetmaps rejects unsafe install path" \
  test_uninstall_openstreetmaps_rejects_unsafe_install_path
run_test_case "uninstall-openstreetmaps removes only the leaflet dir" \
  test_uninstall_openstreetmaps_removes_leaflet_dir_only

finish_tests
