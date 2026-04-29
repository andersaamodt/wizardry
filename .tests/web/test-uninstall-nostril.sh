#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/web/uninstall-nostril --help
  assert_success
  assert_output_contains "Usage: uninstall-nostril"
}

test_success_when_tooling_missing() {
  tmp_bin=$(temp-dir uninstall-nostril-bin)
  PATH="$tmp_bin:/usr/bin:/bin:/usr/sbin:/sbin" run_spell spells/web/uninstall-nostril
  assert_success
  assert_output_contains "not installed"
  rm -rf "$tmp_bin"
}

test_removes_local_binaries() {
  tmp_root=$(temp-dir uninstall-nostril-root)
  tmp_bin="$tmp_root/bin"
  mkdir -p "$tmp_bin"
  cat > "$tmp_bin/nostril" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat > "$tmp_bin/nak" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp_bin/nostril" "$tmp_bin/nak"

  run_cmd env XDG_BIN_HOME="$tmp_bin" PATH="$tmp_bin:$WIZARDRY_IMPS_PATH:/usr/bin:/bin:/usr/sbin:/sbin" \
    "$ROOT_DIR/spells/web/uninstall-nostril"
  assert_success
  [ ! -f "$tmp_bin/nostril" ] || {
    TEST_FAILURE_REASON="nostril binary was not removed"
    rm -rf "$tmp_root"
    return 1
  }
  [ ! -f "$tmp_bin/nak" ] || {
    TEST_FAILURE_REASON="nak binary was not removed"
    rm -rf "$tmp_root"
    return 1
  }

  rm -rf "$tmp_root"
}

run_test_case "uninstall-nostril shows help" test_help
run_test_case "uninstall-nostril succeeds when tooling is missing" test_success_when_tooling_missing
run_test_case "uninstall-nostril removes local binaries" test_removes_local_binaries

finish_tests
