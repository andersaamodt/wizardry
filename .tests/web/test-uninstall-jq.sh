#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/web/uninstall-jq --help
  assert_success
  assert_output_contains "Usage: uninstall-jq"
}

test_success_when_jq_missing() {
  tmp_bin=$(temp-dir uninstall-jq-bin)
  PATH="$tmp_bin:/usr/bin:/bin:/usr/sbin:/sbin" run_spell spells/web/uninstall-jq
  assert_success
  assert_output_contains "jq is not installed"
  rm -rf "$tmp_bin"
}

test_removes_local_binary() {
  tmp_root=$(temp-dir uninstall-jq-root)
  tmp_bin="$tmp_root/bin"
  mkdir -p "$tmp_bin"
  cat > "$tmp_bin/jq" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp_bin/jq"

  run_cmd env XDG_BIN_HOME="$tmp_bin" PATH="$tmp_bin:$WIZARDRY_IMPS_PATH:/usr/bin:/bin:/usr/sbin:/sbin" \
    "$ROOT_DIR/spells/web/uninstall-jq"
  assert_success
  [ ! -f "$tmp_bin/jq" ] || {
    TEST_FAILURE_REASON="jq binary was not removed"
    rm -rf "$tmp_root"
    return 1
  }

  rm -rf "$tmp_root"
}

run_test_case "uninstall-jq shows help" test_help
run_test_case "uninstall-jq succeeds when jq is missing" test_success_when_jq_missing
run_test_case "uninstall-jq removes local binary" test_removes_local_binary

finish_tests
