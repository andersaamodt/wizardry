#!/bin/sh
# Behavioral coverage for install-go2rtc.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/webcam/install-go2rtc"

test_install_go2rtc_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: install-go2rtc" || return 1
}

test_install_go2rtc_rejects_unsupported_platform() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/uname" <<'EOF'
#!/bin/sh
case "${1-}" in
  -s) printf '%s\n' Plan9 ;;
  -m) printf '%s\n' mips ;;
esac
EOF
  chmod +x "$stub_dir/uname"

  run_cmd env \
    HOME="$tmpdir/home" \
    PATH="$stub_dir:/usr/bin:/bin:/usr/sbin:/sbin" \
    sh "$ROOT_DIR/$target"
  assert_failure || return 1
  assert_error_contains "unsupported platform Plan9/mips" || return 1
}

test_install_go2rtc_installs_downloaded_binary() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"

  cat > "$stub_dir/uname" <<'EOF'
#!/bin/sh
case "${1-}" in
  -s) printf '%s\n' Linux ;;
  -m) printf '%s\n' x86_64 ;;
esac
EOF
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
    -fL)
      shift
      ;;
    *)
      shift
      ;;
  esac
done
printf '%s\n' '#!/bin/sh' > "$out_file"
printf '%s\n' 'exit 0' >> "$out_file"
EOF
  chmod +x "$stub_dir/uname" "$stub_dir/curl"

  run_cmd env \
    HOME="$tmpdir/home" \
    PATH="$stub_dir:/usr/bin:/bin:/usr/sbin:/sbin" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  [ -x "$tmpdir/home/.local/bin/go2rtc" ] || {
    TEST_FAILURE_REASON="install-go2rtc did not install go2rtc to ~/.local/bin"
    return 1
  }
}

run_test_case "install-go2rtc shows help" test_install_go2rtc_help
run_test_case "install-go2rtc rejects unsupported platforms" \
  test_install_go2rtc_rejects_unsupported_platform
run_test_case "install-go2rtc installs the downloaded binary" \
  test_install_go2rtc_installs_downloaded_binary

finish_tests
