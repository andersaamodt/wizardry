#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/ai-dev/install-opencode" --help
  assert_success || {
    TEST_FAILURE_REASON="installer failed: $ERROR"
    return 1
  }
  assert_output_contains "Usage: install-opencode" || return 1
  assert_output_contains "without Homebrew" || return 1
}

test_installs_official_macos_archive() {
  tmp=$(make_tempdir)
  home="$tmp/home"
  stubs="$tmp/stubs"
  mkdir -p "$home" "$stubs"
  cat >"$stubs/uname" <<'SH'
#!/bin/sh
case ${1-} in
  -s) printf '%s\n' Darwin ;;
  -m) printf '%s\n' arm64 ;;
  *) printf '%s\n' Darwin ;;
esac
SH
  cat >"$stubs/curl" <<'SH'
#!/bin/sh
output=""
url=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) shift; output=$1 ;;
    http*) url=$1 ;;
  esac
  shift
done
printf '%s\n' "$url" >"$OPENCODE_URL_LOG"
: >"$output"
SH
  cat >"$stubs/unzip" <<'SH'
#!/bin/sh
dest=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -d) shift; dest=$1 ;;
  esac
  shift
done
mkdir -p "$dest"
cat >"$dest/opencode" <<'BIN'
#!/bin/sh
printf '%s\n' 1.2.3
BIN
SH
  chmod +x "$stubs/uname" "$stubs/curl" "$stubs/unzip"

  run_cmd env \
    HOME="$home" \
    AI_DEV_OPENCODE_PATH="$home/.local/bin/opencode" \
    OPENCODE_URL_LOG="$tmp/url" \
    PATH="$stubs:$PATH" \
    "$ROOT_DIR/spells/.arcana/ai-dev/install-opencode"

  assert_success || {
    TEST_FAILURE_REASON="installer failed: $ERROR"
    return 1
  }
  [ -x "$home/.local/bin/opencode" ] || {
    TEST_FAILURE_REASON="OpenCode binary was not installed"
    return 1
  }
  grep -F 'opencode-darwin-arm64.zip' "$tmp/url" >/dev/null || {
    TEST_FAILURE_REASON="installer selected the wrong release asset"
    return 1
  }
}

run_test_case "install-opencode shows help" test_help
run_test_case "install-opencode installs official macOS archive" test_installs_official_macos_archive
finish_tests
