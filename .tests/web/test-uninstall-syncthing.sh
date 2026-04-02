#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_cmd sh "$ROOT_DIR/spells/web/uninstall-syncthing" --help
  assert_success
  assert_output_contains "Usage: uninstall-syncthing"
}

test_success_when_syncthing_already_absent() {
  tmp_bin=$(temp-dir uninstall-syncthing-bin)
  run_cmd env PATH="$tmp_bin" sh "$ROOT_DIR/spells/web/uninstall-syncthing"
  assert_success
  assert_output_contains "already absent"
  rm -rf "$tmp_bin"
}

test_failure_without_supported_package_manager() {
  tmp_bin=$(temp-dir uninstall-syncthing-bin)
  cat > "$tmp_bin/syncthing" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp_bin/syncthing"

  run_cmd env PATH="$tmp_bin" sh "$ROOT_DIR/spells/web/uninstall-syncthing"
  assert_failure
  assert_output_contains "no supported package manager"
  rm -rf "$tmp_bin"
}

run_test_case "uninstall-syncthing shows help" test_help
run_test_case "uninstall-syncthing succeeds when syncthing is already absent" test_success_when_syncthing_already_absent
run_test_case "uninstall-syncthing fails clearly without package manager" test_failure_without_supported_package_manager

finish_tests
