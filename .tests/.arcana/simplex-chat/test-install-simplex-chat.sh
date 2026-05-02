#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="$ROOT_DIR/spells/.arcana/simplex-chat/install-simplex-chat"

spell_is_executable() {
  [ -x "$target" ]
}

run_test_case "install/simplex-chat/install-simplex-chat is executable" spell_is_executable

renders_usage_information() {
  run_cmd "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: install-simplex-chat" || return 1
}

run_test_case "install-simplex-chat shows usage via --help" renders_usage_information

write_fake_simplex_binary() {
  fake_bin=$1
  cat >"$fake_bin" <<'SHI'
#!/bin/sh
case "${1-}" in
  -h|--help)
    printf '%s\n' "SimpleX fake help"
    exit 0
    ;;
  --version)
    printf '%s\n' "simplex-chat fake"
    exit 0
    ;;
esac
exit 0
SHI
  chmod +x "$fake_bin"
}

write_curl_stub() {
  stub_path=$1
  cat >"$stub_path" <<'SHI'
#!/bin/sh
printf '%s\n' "$*" >>"${CURL_LOG:-/dev/null}"
output=
url=
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o)
      shift
      output=${1-}
      ;;
    http*|file:*)
      url=$1
      ;;
  esac
  shift
done
[ -n "$output" ] || exit 2
case "$url" in
  *release*)
    cp "$RELEASE_JSON" "$output"
    ;;
  *simplex-bin*)
    cp "$FAKE_SIMPLEX_BIN" "$output"
    ;;
  *)
    exit 3
    ;;
esac
SHI
  chmod +x "$stub_path"
}

write_release_json() {
  json_path=$1
  digest=$2
  cat >"$json_path" <<EOFJSON
{
  "tag_name": "vtest",
  "assets": [
    {
      "name": "simplex-chat-test",
      "browser_download_url": "https://example.invalid/simplex-bin",
      "digest": "sha256:$digest"
    }
  ]
}
EOFJSON
}

installs_official_asset_with_digest_check() {
  tmp=$(make_tempdir)
  fake_bin="$tmp/simplex-chat-test"
  release_json="$tmp/release.json"
  write_fake_simplex_binary "$fake_bin"
  digest=$(shasum -a 256 "$fake_bin" | awk '{print $1}')
  write_release_json "$release_json" "$digest"
  write_curl_stub "$tmp/curl"

  run_cmd env \
    HOME="$tmp/home" \
    XDG_STATE_HOME="$tmp/state" \
    XDG_BIN_HOME="$tmp/bin" \
    WIZARDRY_SIMPLEX_ROOT="$tmp/state/wizardry/simplex" \
    WIZARDRY_SIMPLEX_ASSET_NAME="simplex-chat-test" \
    WIZARDRY_SIMPLEX_RELEASE_API_URL="https://example.invalid/release" \
  RELEASE_JSON="$release_json" \
  FAKE_SIMPLEX_BIN="$fake_bin" \
  CURL_LOG="$tmp/curl.log" \
  PATH="$tmp:$PATH" \
  "$target"

  assert_success || return 1
  [ -x "$tmp/state/wizardry/simplex/current/simplex-chat" ] || {
    TEST_FAILURE_REASON="current SimpleX binary not installed"
    return 1
  }
  [ -x "$tmp/bin/simplex-chat" ] || {
    TEST_FAILURE_REASON="user-local simplex-chat link not installed"
    return 1
  }
  assert_file_contains "$tmp/state/wizardry/simplex/install.conf" "version=vtest" || return 1
  assert_file_contains "$tmp/state/wizardry/simplex/install.conf" "sha256=$digest" || return 1
  assert_file_contains "$tmp/curl.log" "--retry 3" || return 1
  assert_file_contains "$tmp/curl.log" "--speed-limit 1024" || return 1
  assert_file_contains "$tmp/curl.log" "--speed-time 60" || return 1
}

run_test_case "install-simplex-chat downloads verifies and links official CLI" installs_official_asset_with_digest_check

rejects_digest_mismatch() {
  tmp=$(make_tempdir)
  fake_bin="$tmp/simplex-chat-test"
  release_json="$tmp/release.json"
  write_fake_simplex_binary "$fake_bin"
  write_release_json "$release_json" "0000000000000000000000000000000000000000000000000000000000000000"
  write_curl_stub "$tmp/curl"

  run_cmd env \
    HOME="$tmp/home" \
    XDG_STATE_HOME="$tmp/state" \
    XDG_BIN_HOME="$tmp/bin" \
    WIZARDRY_SIMPLEX_ROOT="$tmp/state/wizardry/simplex" \
    WIZARDRY_SIMPLEX_ASSET_NAME="simplex-chat-test" \
    WIZARDRY_SIMPLEX_RELEASE_API_URL="https://example.invalid/release" \
    RELEASE_JSON="$release_json" \
    FAKE_SIMPLEX_BIN="$fake_bin" \
    PATH="$tmp:$PATH" \
    "$target"

  assert_failure || return 1
  assert_error_contains "sha256 mismatch" || return 1
  [ ! -e "$tmp/state/wizardry/simplex/current/simplex-chat" ] || {
    TEST_FAILURE_REASON="current link should not be created after digest mismatch"
    return 1
  }
}

run_test_case "install-simplex-chat rejects release digest mismatch" rejects_digest_mismatch

finish_tests
