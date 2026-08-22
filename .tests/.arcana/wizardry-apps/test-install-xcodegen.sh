#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_cmd "$ROOT_DIR/spells/.arcana/wizardry-apps/install-xcodegen" --help
  assert_success
  assert_output_contains "Usage: install-xcodegen"
}

installs_xcodegen_into_xdg_root() {
  tmpdir=$(make_tempdir)
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
  *api.github.com/repos/yonaskolb/XcodeGen/releases/latest)
    cat >"$out" <<'JSON'
{
  "assets": [
    { "browser_download_url": "https://github.com/yonaskolb/XcodeGen/releases/download/2.45.4/xcodegen.zip" }
  ]
}
JSON
    ;;
  *xcodegen.zip)
    printf '%s\n' archive >"$out"
    ;;
  *) exit 3 ;;
esac
SH
  chmod +x "$stub_dir/curl"

  cat >"$stub_dir/unzip" <<'SH'
#!/bin/sh
dest_dir=$4
mkdir -p "$dest_dir/bin"
cat >"$dest_dir/bin/xcodegen" <<'XCODEGEN'
#!/bin/sh
exit 0
XCODEGEN
chmod +x "$dest_dir/bin/xcodegen"
SH
  chmod +x "$stub_dir/unzip"

  run_cmd env \
    PATH="$stub_dir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    XDG_DATA_HOME="$tmpdir/data" \
    XDG_BIN_HOME="$tmpdir/bin-home" \
    "$ROOT_DIR/spells/.arcana/wizardry-apps/install-xcodegen"

  assert_success || return 1
  assert_path_exists "$tmpdir/data/wizardry-apps/toolchains/xcodegen/current/xcodegen"
  assert_path_exists "$tmpdir/bin-home/xcodegen"
}

test_xcodegen_installer_does_not_call_homebrew() {
  if grep -q 'brew ' "$ROOT_DIR/spells/.arcana/wizardry-apps/install-xcodegen" "$ROOT_DIR/spells/.arcana/wizardry-apps/wizardry-apps-common"; then
    TEST_FAILURE_REASON="xcodegen installer should not call Homebrew"
    return 1
  fi
}

run_test_case "install-xcodegen shows help" shows_help
run_test_case "install-xcodegen installs into XDG root" installs_xcodegen_into_xdg_root
run_test_case "install-xcodegen does not call Homebrew" test_xcodegen_installer_does_not_call_homebrew

finish_tests
