#!/bin/sh
# Behavioral coverage for openstreetmaps-menu.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/openstreetmaps/openstreetmaps-menu"

test_openstreetmaps_menu_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: openstreetmaps-menu" || return 1
}

test_openstreetmaps_menu_has_content() {
  [ -s "$ROOT_DIR/$target" ] || {
    TEST_FAILURE_REASON="spell has no content: $target"
    return 1
  }
}

test_openstreetmaps_menu_shows_install_toggle_when_assets_missing() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"

  cat > "$stub_dir/menu" <<'EOF'
#!/bin/sh
printf '%s\n' "$@"
exit 130
EOF
  chmod +x "$stub_dir/menu"

  run_cmd env \
    HOME="$tmpdir/home" \
    WIZARDRY_WEB_JS_DIR="$tmpdir/js" \
    PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/menu:/usr/bin:/bin:/usr/sbin:/sbin" \
    WIZARDRY_DIR="$ROOT_DIR" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "[ ] OpenStreetMap web assets" || return 1
}

test_openstreetmaps_menu_shows_uninstall_toggle_when_assets_present() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  install_root="$tmpdir/js"
  mkdir -p "$stub_dir" "$install_root/leaflet/images"
  for asset in leaflet.css leaflet.js images/marker-icon.png images/marker-icon-2x.png images/marker-shadow.png; do
    printf 'asset\n' > "$install_root/leaflet/$asset"
  done

  cat > "$stub_dir/menu" <<'EOF'
#!/bin/sh
printf '%s\n' "$@"
exit 130
EOF
  chmod +x "$stub_dir/menu"

  run_cmd env \
    HOME="$tmpdir/home" \
    WIZARDRY_WEB_JS_DIR="$install_root" \
    PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/menu:/usr/bin:/bin:/usr/sbin:/sbin" \
    WIZARDRY_DIR="$ROOT_DIR" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "[X] OpenStreetMap web assets" || return 1
}

run_test_case "openstreetmaps-menu shows help" test_openstreetmaps_menu_help
run_test_case "openstreetmaps-menu has content" test_openstreetmaps_menu_has_content
run_test_case "openstreetmaps-menu shows install toggle when assets missing" \
  test_openstreetmaps_menu_shows_install_toggle_when_assets_missing
run_test_case "openstreetmaps-menu shows uninstall toggle when assets present" \
  test_openstreetmaps_menu_shows_uninstall_toggle_when_assets_present

finish_tests
