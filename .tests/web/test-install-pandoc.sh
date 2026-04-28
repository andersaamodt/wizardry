#!/bin/sh
# Behavioral coverage for install-pandoc spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/install-pandoc"

test_install_pandoc_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_install_pandoc_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_install_pandoc_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

test_install_pandoc_rejects_untrusted_release_url() {
  tmp_bin=$(temp-dir install-pandoc-bin)
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
  https://api.github.com/repos/jgm/pandoc/releases/latest)
    printf '%s\n' '{"assets":[{"browser_download_url":"file:///tmp/pandoc-3.1-macOS-arm64.tar.gz"}]}'
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

  CURL="$tmp_bin/curl" PANDOC="$tmp_bin/missing-pandoc" XDG_BIN_HOME="$tmp_bin" \
    PATH="$tmp_bin:$WIZARDRY_IMPS_PATH:/usr/bin:/bin:/usr/sbin:/sbin" \
    run_spell "$target"

  assert_failure || return 1
  [ ! -e "$bad_marker" ] || {
    TEST_FAILURE_REASON="install-pandoc downloaded an untrusted release URL"
    return 1
  }
  [ ! -x "$tmp_bin/pandoc" ] || {
    TEST_FAILURE_REASON="install-pandoc installed pandoc from an untrusted release URL"
    return 1
  }

  rm -rf "$tmp_bin"
}

run_test_case "install-pandoc spell exists" test_install_pandoc_exists
run_test_case "install-pandoc spell is executable" test_install_pandoc_executable
run_test_case "install-pandoc spell --help is callable" test_install_pandoc_help_callable
run_test_case "install-pandoc rejects untrusted release URLs" \
  test_install_pandoc_rejects_untrusted_release_url

finish_tests
