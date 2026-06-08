#!/bin/sh
# Behavioral coverage for install-openstreetmaps.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/openstreetmaps/install-openstreetmaps"

test_install_openstreetmaps_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: install-openstreetmaps" || return 1
}

test_install_openstreetmaps_rejects_invalid_version() {
  tmpdir=$(make_tempdir)
  run_cmd env \
    HOME="$tmpdir/home" \
    OPENSTREETMAPS_LEAFLET_VERSION='1.9.4/../../bad' \
    PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" \
    WIZARDRY_DIR="$ROOT_DIR" \
    sh "$ROOT_DIR/$target"
  assert_failure || return 1
  assert_error_contains "invalid Leaflet version" || return 1
}

test_install_openstreetmaps_installs_assets_via_curl() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  install_root="$tmpdir/js"
  mkdir -p "$stub_dir"

  cat > "$stub_dir/curl" <<'EOF'
#!/bin/sh
set -eu
out_file=
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o)
      out_file=$2
      shift 2
      ;;
    -fsSL)
      shift
      ;;
    *)
      url=$1
      shift
      ;;
  esac
done
printf '%s\n' "${url##*/}" > "$out_file"
EOF
  chmod +x "$stub_dir/curl"

  run_cmd env \
    HOME="$tmpdir/home" \
    OPENSTREETMAPS_LEAFLET_BASE_URL='https://assets.example/leaflet' \
    OPENSTREETMAPS_LEAFLET_LICENSE_URL='https://assets.example/LICENSE' \
    WIZARDRY_WEB_JS_DIR="$install_root" \
    PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" \
    WIZARDRY_DIR="$ROOT_DIR" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  [ -s "$install_root/leaflet/leaflet.css" ] || return 1
  [ -s "$install_root/leaflet/leaflet.js" ] || return 1
  [ -s "$install_root/leaflet/images/marker-icon.png" ] || return 1
  [ -s "$install_root/leaflet/LICENSE" ] || return 1
}

run_test_case "install-openstreetmaps shows help" test_install_openstreetmaps_help
run_test_case "install-openstreetmaps rejects invalid version" \
  test_install_openstreetmaps_rejects_invalid_version
run_test_case "install-openstreetmaps installs assets via curl" \
  test_install_openstreetmaps_installs_assets_via_curl

finish_tests
