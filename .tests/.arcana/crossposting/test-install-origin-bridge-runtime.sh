#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/crossposting/install-origin-bridge-runtime"

test_install_origin_bridge_runtime_help() {
  run_spell "$target" --help
  assert_success && assert_output_contains "origin-bridge-<platform>"
}

test_install_origin_bridge_runtime_writes_wrappers() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  run_cmd env \
    CROSSPOSTING_INSTALL_BIN_DIR="$tmp/bin" \
    XDG_STATE_HOME="$tmp/state" \
    "$ROOT_DIR/$target"
  assert_success || return 1
  assert_file_contains "$tmp/state/wizardry/crossposting/origin-bridge-runtime.manifest" "origin-bridge-dispatch" || return 1
  [ -x "$tmp/bin/origin-bridge-dispatch" ] || {
    TEST_FAILURE_REASON="missing dispatch executable"
    return 1
  }
  [ -x "$tmp/bin/origin-bridge-misskey" ] || {
    TEST_FAILURE_REASON="missing misskey wrapper"
    return 1
  }
}

test_install_origin_bridge_runtime_installs_real_http_client() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)

  run_cmd env \
    CROSSPOSTING_INSTALL_BIN_DIR="$tmp/bin" \
    XDG_STATE_HOME="$tmp/state" \
    "$ROOT_DIR/$target"
  assert_success || return 1

  mkdir -p "$tmp/mock-bin"
  cat >"$tmp/mock-bin/curl" <<'EOF'
#!/bin/sh
set -eu
url=
while [ $# -gt 0 ]; do
  case "$1" in
    -H)
      printf '%s\n' "$2" >>"$MOCK_HEADERS"
      shift 2
      ;;
    --data-binary)
      cat "${2#@}" >"$MOCK_BODY"
      shift 2
      ;;
    -X)
      shift 2
      ;;
    -fsS)
      shift
      ;;
    *)
      url=$1
      shift
      ;;
  esac
done
    printf '%s\n' "$url" >"$MOCK_URL"
    printf '{"remote_id":"bridge-id","remote_url":"https://bridge.example/reddit/bridge-id"}'
EOF
  chmod +x "$tmp/mock-bin/curl"
  : >"$tmp/url"
  : >"$tmp/body"
  : >"$tmp/headers"

  run_cmd env \
    PATH="$tmp/mock-bin:$tmp/bin:/usr/bin:/bin" \
    ORIGIN_BRIDGE_REDDIT_BASE_URL="https://bridge.example/reddit" \
    ORIGIN_BRIDGE_REDDIT_TOKEN="wizard-token" \
    MOCK_URL="$tmp/url" \
    MOCK_BODY="$tmp/body" \
    MOCK_HEADERS="$tmp/headers" \
    "$tmp/bin/origin-bridge-reddit" emit <<'EOF'
{"title":"Test bridge payload"}
EOF
  assert_success || return 1
  assert_output_contains '"remote_id":"bridge-id"' || return 1
  assert_file_contains "$tmp/url" 'https://bridge.example/reddit/emit' || return 1
  assert_file_contains "$tmp/body" '{"title":"Test bridge payload"}' || return 1
  assert_file_contains "$tmp/headers" 'Authorization: Bearer wizard-token' || return 1
}

run_test_case "install-origin-bridge-runtime shows help" test_install_origin_bridge_runtime_help
run_test_case "install-origin-bridge-runtime writes wrappers" test_install_origin_bridge_runtime_writes_wrappers
run_test_case "install-origin-bridge-runtime installs real HTTP bridge clients" test_install_origin_bridge_runtime_installs_real_http_client
finish_tests
