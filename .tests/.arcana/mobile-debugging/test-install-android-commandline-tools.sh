#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/install-android-commandline-tools" --help
  assert_success
  assert_output_contains "Usage: install-android-commandline-tools"
}

installs_commandline_tools_into_xdg_root() {
  tmpdir=$(make_tempdir)
  sdk_root="$tmpdir/data/theurgy/mobile-debugging/android-sdk"
  stub_dir="$tmpdir/bin"
  mkdir -p "$stub_dir"

  cat >"$stub_dir/curl" <<'SH'
#!/bin/sh
out=
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) out=$2; shift 2 ;;
    --) shift; url=$1; shift ;;
    -*) shift ;;
    *) url=$1; shift ;;
  esac
done
[ -n "$out" ] || exit 2
case "${url-}" in
  *repository2-1.xml)
    cat >"$out" <<'XML'
<sdk:sdk-repository>
  <remotePackage path="cmdline-tools;latest">
    <archives>
      <archive>
        <complete>
          <url>commandlinetools-mac-15641748_latest.zip</url>
          <url>commandlinetools-linux-15641748_latest.zip</url>
        </complete>
      </archive>
    </archives>
  </remotePackage>
</sdk:sdk-repository>
XML
    ;;
  *commandlinetools-mac-15641748_latest.zip|*commandlinetools-linux-15641748_latest.zip)
    printf '%s\n' archive >"$out"
    ;;
  *) exit 3 ;;
esac
SH
  chmod +x "$stub_dir/curl"

  cat >"$stub_dir/unzip" <<'SH'
#!/bin/sh
dest_dir=$4
mkdir -p "$dest_dir/cmdline-tools/bin"
cat >"$dest_dir/cmdline-tools/bin/sdkmanager" <<'SDK'
#!/bin/sh
exit 0
SDK
chmod +x "$dest_dir/cmdline-tools/bin/sdkmanager"
SH
  chmod +x "$stub_dir/unzip"

  run_cmd env \
    PATH="$stub_dir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    XDG_DATA_HOME="$tmpdir/data" \
    WIZARDRY_VOICE_AUDIO_UNAME_S=Darwin \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/install-android-commandline-tools"

  assert_success || return 1
  assert_path_exists "$sdk_root/cmdline-tools/latest/bin/sdkmanager"
}

run_test_case "install-android-commandline-tools shows help" shows_help
run_test_case "install-android-commandline-tools installs into XDG root" installs_commandline_tools_into_xdg_root

finish_tests
