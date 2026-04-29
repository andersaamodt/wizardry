#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/install-supercollider"

test_help() {
  run_spell "$target" --help
  assert_success
  assert_output_contains "Usage: install-supercollider"
}

test_rejects_untrusted_release_url() {
  tmp_bin=$(temp-dir install-supercollider-bin)
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
  https://api.github.com/repos/supercollider/supercollider/releases/latest)
    printf '%s\n' '{"assets":[{"browser_download_url":"file:///tmp/SuperCollider-3.13.0-macOS-universal.dmg"}]}'
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
  cat > "$tmp_bin/hdiutil" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$tmp_bin/curl" "$tmp_bin/hdiutil"

  run_cmd env \
    CURL="$tmp_bin/curl" \
    SCLANG="$tmp_bin/missing-sclang" \
    SUPERCOLLIDER_APP_PATH="$tmp_bin/missing/SuperCollider.app" \
    PATH="$tmp_bin:$WIZARDRY_IMPS_PATH:/usr/bin:/bin:/usr/sbin:/sbin" \
    sh "$ROOT_DIR/$target"

  assert_failure || return 1
  [ ! -e "$bad_marker" ] || {
    TEST_FAILURE_REASON="install-supercollider downloaded an untrusted release URL"
    return 1
  }

  rm -rf "$tmp_bin"
}

run_test_case "install-supercollider shows help" test_help
run_test_case "install-supercollider rejects untrusted release URLs" \
  test_rejects_untrusted_release_url

finish_tests
