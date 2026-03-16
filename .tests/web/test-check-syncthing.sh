#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_cmd sh "$ROOT_DIR/spells/web/check-syncthing" --help
  assert_success
  assert_output_contains "Usage: check-syncthing"
}

test_ok_when_syncthing_exists() {
  tmp_bin=$(temp-dir check-syncthing-bin)
  cat > "$tmp_bin/syncthing" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp_bin/syncthing"

  run_cmd env PATH="$tmp_bin:/usr/bin:/bin:/usr/sbin:/sbin" sh "$ROOT_DIR/spells/web/check-syncthing"
  assert_success
  assert_output_contains "status=ok"

  rm -rf "$tmp_bin"
}

test_bad_when_syncthing_missing() {
  tmp_bin=$(temp-dir check-syncthing-bin)
  run_cmd env PATH="$tmp_bin" sh "$ROOT_DIR/spells/web/check-syncthing"
  assert_success
  assert_output_contains "status=bad"
  assert_output_contains "Syncthing is not installed"
  rm -rf "$tmp_bin"
}

run_test_case "check-syncthing shows help" test_help
run_test_case "check-syncthing returns ok when syncthing exists" test_ok_when_syncthing_exists
run_test_case "check-syncthing reports missing syncthing" test_bad_when_syncthing_missing

finish_tests
