#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/install-android-platform-tools" --help
  assert_success
  assert_output_contains "Usage: install-android-platform-tools"
}

installs_platform_tools_into_xdg_root() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data/theurgy/mobile-debugging/android-sdk"
  stub_dir="$tmpdir/bin"
  mkdir -p "$stub_dir"

  cat >"$stub_dir/curl" <<'SH'
#!/bin/sh
cat "${CURL_PAYLOAD:?}"
SH
  chmod +x "$stub_dir/curl"

  cat >"$stub_dir/unzip" <<'SH'
#!/bin/sh
archive_file=$2
dest_dir=$4
mkdir -p "$dest_dir/platform-tools"
cat >"$dest_dir/platform-tools/adb" <<'ADB'
#!/bin/sh
exit 0
ADB
chmod +x "$dest_dir/platform-tools/adb"
test -f "$archive_file"
exit 0
SH
  chmod +x "$stub_dir/unzip"

  payload="$tmpdir/payload.zip"
  printf 'payload' >"$payload"

  run_cmd env PATH="$stub_dir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" CURL_PAYLOAD="$payload" XDG_DATA_HOME="$tmpdir/data" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/install-android-platform-tools"

  assert_success || return 1
  assert_path_exists "$sdk_root/platform-tools/adb"
}

run_test_case "install-android-platform-tools shows help" shows_help
run_test_case "install-android-platform-tools installs into XDG root" installs_platform_tools_into_xdg_root

finish_tests
