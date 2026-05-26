#!/bin/sh
# Behavioral coverage for is-go2rtc-installed.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/webcam/is-go2rtc-installed"

test_is_go2rtc_installed_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: is-go2rtc-installed" || return 1
}

test_is_go2rtc_installed_fails_without_binary() {
  tmpdir=$(make_tempdir)
  run_cmd env HOME="$tmpdir/home" PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" sh "$ROOT_DIR/$target"
  assert_failure || return 1
}

test_is_go2rtc_installed_finds_user_local_binary() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/home/.local/bin"
  cat > "$tmpdir/home/.local/bin/go2rtc" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmpdir/home/.local/bin/go2rtc"

  run_cmd env HOME="$tmpdir/home" PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" sh "$ROOT_DIR/$target"
  assert_success || return 1
}

run_test_case "is-go2rtc-installed shows help" test_is_go2rtc_installed_help
run_test_case "is-go2rtc-installed fails without go2rtc" \
  test_is_go2rtc_installed_fails_without_binary
run_test_case "is-go2rtc-installed finds the user-local binary" \
  test_is_go2rtc_installed_finds_user_local_binary

finish_tests
