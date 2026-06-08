#!/bin/sh
# Behavioral coverage for check-supercollider.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/check-supercollider"

test_check_supercollider_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: check-supercollider" || return 1
}

test_check_supercollider_reports_missing_when_unavailable() {
  tmpdir=$(make_tempdir)
  run_cmd env \
    HOME="$tmpdir/home" \
    PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" \
    SCLANG="missing-sclang" \
    SUPERCOLLIDER_APP_PATH="$tmpdir/home/Applications/MissingSuperCollider.app" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "status=bad" || return 1
  assert_output_contains "SuperCollider is not installed." || return 1
}

test_check_supercollider_reports_ok_when_sclang_exists() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/sclang" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub_dir/sclang"

  run_cmd env \
    HOME="$tmpdir/home" \
    PATH="$stub_dir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin:/usr/sbin:/sbin" \
    SCLANG="sclang" \
    SUPERCOLLIDER_APP_PATH="$tmpdir/home/Applications/MissingSuperCollider.app" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "status=ok" || return 1
  assert_output_contains "SuperCollider is available on PATH." || return 1
}

run_test_case "check-supercollider shows help" test_check_supercollider_help
run_test_case "check-supercollider reports missing when unavailable" \
  test_check_supercollider_reports_missing_when_unavailable
run_test_case "check-supercollider reports ok when sclang exists" \
  test_check_supercollider_reports_ok_when_sclang_exists

finish_tests
