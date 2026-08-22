#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_supercollider_spells_show_help() {
  for spell in install-supercollider uninstall-supercollider is-supercollider-installed; do
    run_cmd "$ROOT_DIR/spells/.arcana/voice-audio/$spell" --help
    assert_success || return 1
  done
}

test_supercollider_installers_do_not_call_homebrew() {
  if grep -q 'brew ' "$ROOT_DIR/spells/.arcana/voice-audio/install-supercollider" "$ROOT_DIR/spells/.arcana/voice-audio/uninstall-supercollider"; then
    TEST_FAILURE_REASON="SuperCollider installers should not call Homebrew"
    return 1
  fi
}

test_rejects_untrusted_release_url() {
  target="$ROOT_DIR/spells/.arcana/voice-audio/install-supercollider"
  tmp_bin=$(temp-dir install-supercollider-bin)
  bad_marker="$tmp_bin/bad-download"
  cat >"$tmp_bin/curl" <<EOF
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
    printf '%s\n' "downloaded untrusted URL" >"$bad_marker"
    [ -n "\$out_file" ] && : >"\$out_file"
    ;;
  *)
    exit 1
    ;;
esac
EOF
  cat >"$tmp_bin/hdiutil" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$tmp_bin/curl" "$tmp_bin/hdiutil"

  run_cmd env \
    CURL="$tmp_bin/curl" \
    SCLANG="$tmp_bin/missing-sclang" \
    SUPERCOLLIDER_APP_PATH="$tmp_bin/missing/SuperCollider.app" \
    PATH="$tmp_bin:$WIZARDRY_IMPS_PATH:/usr/bin:/bin:/usr/sbin:/sbin" \
    sh "$target"

  assert_failure || return 1
  [ ! -e "$bad_marker" ] || {
    TEST_FAILURE_REASON="install-supercollider downloaded an untrusted release URL"
    return 1
  }
}

test_replaces_existing_app_transactionally() {
  target="$ROOT_DIR/spells/.arcana/voice-audio/install-supercollider"
  if ! grep -q 'backup_bundle=' "$target"; then
    TEST_FAILURE_REASON="installer should stage a backup before replacing an app bundle"
    return 1
  fi
  if grep -q 'rm -rf "$target_bundle"' "$target"; then
    TEST_FAILURE_REASON="installer should not delete the existing app before replacement"
    return 1
  fi
  if ! grep -q 'mv "$backup_bundle" "$target_bundle"' "$target"; then
    TEST_FAILURE_REASON="installer should restore the previous app if replacement fails"
    return 1
  fi
}

run_test_case "SuperCollider spells show help" test_supercollider_spells_show_help
run_test_case "SuperCollider installers do not call Homebrew" test_supercollider_installers_do_not_call_homebrew
run_test_case "install-supercollider rejects untrusted release URLs" \
  test_rejects_untrusted_release_url
run_test_case "install-supercollider replaces existing app transactionally" \
  test_replaces_existing_app_transactionally

finish_tests
