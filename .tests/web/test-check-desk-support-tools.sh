#!/bin/sh
# Behavioral coverage for check-desk-support-tools.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/check-desk-support-tools"

test_check_desk_support_tools_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: check-desk-support-tools" || return 1
}

test_check_desk_support_tools_ok() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/bin"
  for tool in jq nak nostril; do
    cat >"$tmpdir/bin/$tool" <<'SH'
#!/bin/sh
exit 0
SH
    chmod +x "$tmpdir/bin/$tool"
  done
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" \
    PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "status=ok" || return 1
}

test_check_desk_support_tools_reports_missing() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/bin"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" \
    PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "status=bad" || return 1
}

run_test_case "check-desk-support-tools shows help" test_check_desk_support_tools_help
run_test_case "check-desk-support-tools reports ok" test_check_desk_support_tools_ok
run_test_case "check-desk-support-tools reports missing tools" test_check_desk_support_tools_reports_missing

finish_tests
