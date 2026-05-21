#!/bin/sh
# Behavioral coverage for crossposting-common.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/crossposting/crossposting-common"

test_crossposting_common_exists() {
  [ -f "$ROOT_DIR/$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_crossposting_common_has_content() {
  [ -s "$ROOT_DIR/$target" ] || {
    TEST_FAILURE_REASON="spell has no content: $target"
    return 1
  }
}

test_crossposting_common_is_sourceable() {
  run_cmd env ROOT_DIR="$ROOT_DIR" /bin/sh -c '
    . "$ROOT_DIR/spells/.arcana/crossposting/crossposting-common"
  '
  assert_success || return 1
}

test_crossposting_common_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

test_crossposting_common_prefers_explicit_install_dir_overrides() {
  run_cmd env ROOT_DIR="$ROOT_DIR" /bin/sh -c '
    . "$ROOT_DIR/spells/.arcana/crossposting/crossposting-common"
    CROSSPOSTING_INSTALL_BIN_DIR=/tmp/crossposting-bin
    CROSSPOSTING_INSTALL_LIB_DIR=/tmp/crossposting-lib
    printf "bin=%s\n" "$(crossposting_install_bin_dir)"
    printf "lib=%s\n" "$(crossposting_install_lib_dir)"
  '
  assert_success || return 1
  assert_output_contains "bin=/tmp/crossposting-bin" || return 1
  assert_output_contains "lib=/tmp/crossposting-lib" || return 1
}

test_crossposting_common_reports_bridge_runtime_availability() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"

  run_cmd env ROOT_DIR="$ROOT_DIR" PATH="$stub_dir:/usr/bin:/bin:/usr/sbin:/sbin" /bin/sh -c '
    . "$ROOT_DIR/spells/.arcana/crossposting/crossposting-common"
    crossposting_bridge_runtime_available
  '
  assert_failure || return 1

  for platform in misskey lemmy kbin reddit x tumblr facebook minds mirror; do
    cat > "$stub_dir/origin-bridge-$platform" <<'EOF'
#!/bin/sh
exit 0
EOF
    chmod +x "$stub_dir/origin-bridge-$platform"
  done

  run_cmd env ROOT_DIR="$ROOT_DIR" PATH="$stub_dir:/usr/bin:/bin:/usr/sbin:/sbin" /bin/sh -c '
    . "$ROOT_DIR/spells/.arcana/crossposting/crossposting-common"
    crossposting_bridge_runtime_available
  '
  assert_success || return 1
}

run_test_case "crossposting-common exists" test_crossposting_common_exists
run_test_case "crossposting-common has content" test_crossposting_common_has_content
run_test_case "crossposting-common is sourceable" test_crossposting_common_is_sourceable
run_test_case "crossposting-common --help is callable" test_crossposting_common_help_callable
run_test_case "crossposting-common prefers explicit install dir overrides" \
  test_crossposting_common_prefers_explicit_install_dir_overrides
run_test_case "crossposting-common reports bridge runtime availability" \
  test_crossposting_common_reports_bridge_runtime_availability
finish_tests
