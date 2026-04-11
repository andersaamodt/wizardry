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

run_test_case "install-origin-bridge-runtime shows help" test_install_origin_bridge_runtime_help
run_test_case "install-origin-bridge-runtime writes wrappers" test_install_origin_bridge_runtime_writes_wrappers
finish_tests
