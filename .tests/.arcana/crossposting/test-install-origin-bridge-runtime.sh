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
  origin_source="$tmp/origin-source"
  mkdir -p "$origin_source/bin" "$origin_source/lib"
  cat >"$origin_source/lib/origin-bridge.sh" <<'EOF'
#!/bin/sh
printf '%s\n' "lib"
EOF
  chmod +x "$origin_source/lib/origin-bridge.sh"
  for platform in misskey lemmy kbin reddit x tumblr facebook minds mirror; do
    cat >"$origin_source/bin/origin-bridge-$platform" <<'EOF'
#!/bin/sh
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
. "$ROOT_DIR/lib/origin-bridge.sh"
EOF
    chmod +x "$origin_source/bin/origin-bridge-$platform"
  done
  run_cmd env \
    ORIGIN_SOURCE_DIR="$origin_source" \
    CROSSPOSTING_INSTALL_BIN_DIR="$tmp/bin" \
    CROSSPOSTING_INSTALL_LIB_DIR="$tmp/lib" \
    XDG_STATE_HOME="$tmp/state" \
    "$ROOT_DIR/$target"
  assert_success || return 1
  assert_file_contains "$tmp/state/wizardry/crossposting/origin-bridge-runtime.manifest" "$tmp/lib/origin-bridge.sh" || return 1
  [ -x "$tmp/lib/origin-bridge.sh" ] || {
    TEST_FAILURE_REASON="missing shared bridge library"
    return 1
  }
  [ -x "$tmp/bin/origin-bridge-misskey" ] || {
    TEST_FAILURE_REASON="missing misskey bridge client"
    return 1
  }
}

test_install_origin_bridge_runtime_installs_origin_sourced_client() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  origin_source="$tmp/origin-source"
  mkdir -p "$origin_source/bin" "$origin_source/lib"
  cat >"$origin_source/lib/origin-bridge.sh" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "${ORIGIN_BRIDGE_TEST_SENTINEL-}" >"${ORIGIN_BRIDGE_TEST_OUTPUT-}"
printf '{"remote_id":"bridge-id"}'
EOF
  chmod +x "$origin_source/lib/origin-bridge.sh"
  cat >"$origin_source/bin/origin-bridge-reddit" <<'EOF'
#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd -P)
. "$ROOT_DIR/lib/origin-bridge.sh"
EOF
  chmod +x "$origin_source/bin/origin-bridge-reddit"
  for platform in misskey lemmy kbin x tumblr facebook minds mirror; do
    cp "$origin_source/bin/origin-bridge-reddit" "$origin_source/bin/origin-bridge-$platform"
  done

  run_cmd env \
    ORIGIN_SOURCE_DIR="$origin_source" \
    CROSSPOSTING_INSTALL_BIN_DIR="$tmp/bin" \
    CROSSPOSTING_INSTALL_LIB_DIR="$tmp/lib" \
    XDG_STATE_HOME="$tmp/state" \
    "$ROOT_DIR/$target"
  assert_success || return 1

  : >"$tmp/output"

  run_cmd env \
    PATH="$tmp/bin:/usr/bin:/bin" \
    ORIGIN_BRIDGE_TEST_SENTINEL="origin-source-client" \
    ORIGIN_BRIDGE_TEST_OUTPUT="$tmp/output" \
    "$tmp/bin/origin-bridge-reddit" emit <<'EOF'
{"title":"Test bridge payload"}
EOF
  assert_success || return 1
  assert_output_contains '"remote_id":"bridge-id"' || return 1
  assert_file_contains "$tmp/output" 'origin-source-client' || return 1
}

run_test_case "install-origin-bridge-runtime shows help" test_install_origin_bridge_runtime_help
run_test_case "install-origin-bridge-runtime writes wrappers" test_install_origin_bridge_runtime_writes_wrappers
run_test_case "install-origin-bridge-runtime installs origin sourced clients" test_install_origin_bridge_runtime_installs_origin_sourced_client
finish_tests
