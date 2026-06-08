#!/bin/sh
# Behavioral coverage for check-desk-stonr.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/check-desk-stonr"

test_check_desk_stonr_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: check-desk-stonr" || return 1
}

test_check_desk_stonr_uses_xdg_bin_home() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/bin"
  cat >"$tmpdir/bin/stonr" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmpdir/bin/stonr"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" \
    PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "status=ok" || return 1
}

test_check_desk_stonr_reports_missing() {
  tmpdir=$(make_tempdir)
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" \
    PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "status=bad" || return 1
}

run_test_case "check-desk-stonr shows help" test_check_desk_stonr_help
run_test_case "check-desk-stonr finds XDG bin stonr" test_check_desk_stonr_uses_xdg_bin_home
run_test_case "check-desk-stonr reports missing stonr" test_check_desk_stonr_reports_missing

finish_tests
