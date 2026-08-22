#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/install-temurin-jdk" --help
  assert_success
  assert_output_contains "Usage: install-temurin-jdk"
}

installs_temurin_into_xdg_root() {
  tmpdir=$(make_tempdir)
  java_root="$tmpdir/data/theurgy/mobile-debugging/java/current"
  stub_dir="$tmpdir/bin"
  mkdir -p "$stub_dir"

  cat >"$stub_dir/curl" <<'SH'
#!/bin/sh
url=
output=
while [ $# -gt 0 ]; do
  case "$1" in
    -o)
      output=$2
      shift 2
      ;;
    --)
      shift
      [ $# -gt 0 ] && url=$1
      break
      ;;
    -*)
      shift
      ;;
    *)
      url=$1
      shift
      ;;
  esac
done

case "$url" in
  *api.adoptium.net*)
    cat "${TEMURIN_RELEASE_JSON:?}" >"${output:-/dev/stdout}"
    ;;
  *)
    cat "${TEMURIN_ARCHIVE_PAYLOAD:?}" >"${output:-/dev/stdout}"
    ;;
esac
SH
  chmod +x "$stub_dir/curl"

  cat >"$stub_dir/shasum" <<'SH'
#!/bin/sh
printf '%s  %s\n' "${TEMURIN_ARCHIVE_SHA:?}" "$3"
SH
  chmod +x "$stub_dir/shasum"

  cat >"$stub_dir/tar" <<'SH'
#!/bin/sh
archive_file=$2
dest_dir=$4
mkdir -p "$dest_dir/OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.19_10/Contents/Home/bin"
cat >"$dest_dir/OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.19_10/Contents/Home/bin/java" <<'JAVA'
#!/bin/sh
exit 0
JAVA
chmod +x "$dest_dir/OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.19_10/Contents/Home/bin/java"
test -f "$archive_file"
exit 0
SH
  chmod +x "$stub_dir/tar"

  release_json="$tmpdir/release.json"
  archive_payload="$tmpdir/temurin.tar.gz"
  cat >"$release_json" <<'JSON'
[
  {
    "release_name": "jdk-17.0.19+10",
    "binary": {
      "package": {
        "checksum": "abc123",
        "link": "https://example.test/OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.19_10.tar.gz",
        "name": "OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.19_10.tar.gz"
      }
    }
  }
]
JSON
  printf 'payload' >"$archive_payload"

  run_cmd env PATH="$stub_dir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    XDG_DATA_HOME="$tmpdir/data" \
    TEMURIN_RELEASE_JSON="$release_json" \
    TEMURIN_ARCHIVE_PAYLOAD="$archive_payload" \
    TEMURIN_ARCHIVE_SHA="abc123" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/install-temurin-jdk"

  assert_success || return 1
  assert_path_exists "$java_root/Contents/Home/bin/java"
  assert_file_contains "$java_root/RELEASE_TAG" "jdk-17.0.19+10"
}

run_test_case "install-temurin-jdk shows help" shows_help
run_test_case "install-temurin-jdk installs into XDG root" installs_temurin_into_xdg_root

finish_tests
