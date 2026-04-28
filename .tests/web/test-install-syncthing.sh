#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_cmd sh "$ROOT_DIR/spells/web/install-syncthing" --help
  assert_success
  assert_output_contains "Usage: install-syncthing"
}

test_success_when_syncthing_already_present() {
  tmp_bin=$(temp-dir install-syncthing-bin)
  cat > "$tmp_bin/syncthing" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp_bin/syncthing"

  run_cmd env PATH="$tmp_bin:$WIZARDRY_IMPS_PATH:/usr/bin:/bin:/usr/sbin:/sbin" \
    sh "$ROOT_DIR/spells/web/install-syncthing"
  assert_success
  assert_output_contains "already installed"

  rm -rf "$tmp_bin"
}

test_failure_without_supported_package_manager() {
  tmp_bin=$(temp-dir install-syncthing-bin)
  run_cmd env PATH="$tmp_bin:$WIZARDRY_IMPS_PATH:/usr/bin:/bin:/usr/sbin:/sbin" \
    SYNCTHING="$tmp_bin/missing-syncthing" CURL="$tmp_bin/missing-curl" \
    sh "$ROOT_DIR/spells/web/install-syncthing"
  assert_failure
  assert_output_contains "no supported package manager"
  rm -rf "$tmp_bin"
}

test_rejects_untrusted_release_url() {
  tmp_bin=$(temp-dir install-syncthing-bin)
  bad_marker="$tmp_bin/bad-download"
  cat > "$tmp_bin/curl" <<EOF
#!/bin/sh
set -eu
out_file=
url=
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    -o)
      out_file=\$2
      shift 2
      ;;
    -fsSL|-f|-s|-S|-L)
      shift
      ;;
    *)
      url=\$1
      shift
      ;;
  esac
done
case "\$url" in
  https://api.github.com/repos/syncthing/syncthing/releases/latest)
    printf '%s\n' '{"assets":[{"browser_download_url":"file:///tmp/syncthing-macos-universal-v1.27.0.zip"}]}'
    ;;
  file://*)
    printf '%s\n' "downloaded untrusted URL" > "$bad_marker"
    [ -n "\$out_file" ] && : > "\$out_file"
    ;;
  *)
    exit 1
    ;;
esac
EOF
  chmod +x "$tmp_bin/curl"

  run_cmd env PATH="$tmp_bin:$WIZARDRY_IMPS_PATH:/usr/bin:/bin:/usr/sbin:/sbin" \
    SYNCTHING="$tmp_bin/missing-syncthing" CURL="$tmp_bin/curl" XDG_BIN_HOME="$tmp_bin" \
    sh "$ROOT_DIR/spells/web/install-syncthing"

  assert_failure || return 1
  [ ! -e "$bad_marker" ] || {
    TEST_FAILURE_REASON="install-syncthing downloaded an untrusted release URL"
    return 1
  }
  [ ! -x "$tmp_bin/syncthing" ] || {
    TEST_FAILURE_REASON="install-syncthing installed from an untrusted release URL"
    return 1
  }

  rm -rf "$tmp_bin"
}

run_test_case "install-syncthing shows help" test_help
run_test_case "install-syncthing succeeds when syncthing already exists" test_success_when_syncthing_already_present
run_test_case "install-syncthing fails clearly without package manager" test_failure_without_supported_package_manager
run_test_case "install-syncthing rejects untrusted release URLs" test_rejects_untrusted_release_url

finish_tests
