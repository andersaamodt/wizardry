#!/bin/sh
# Behavioral coverage for check-desk-static-site-runtime.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/check-desk-static-site-runtime"

test_static_runtime_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: check-desk-static-site-runtime" || return 1
}

test_static_runtime_reports_ok_with_tools() {
  tmpdir=$(make_tempdir)
  for tool in nginx gzip; do
    cat >"$tmpdir/$tool" <<'SH'
#!/bin/sh
exit 0
SH
    chmod +x "$tmpdir/$tool"
  done
  run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "status=ok" || return 1
}

test_static_runtime_reports_missing() {
  tmpdir=$(make_tempdir)
  run_cmd env PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/usr/bin:/bin" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  assert_output_contains "status=bad" || return 1
}

run_test_case "check-desk-static-site-runtime shows help" test_static_runtime_help
run_test_case "check-desk-static-site-runtime reports ok" test_static_runtime_reports_ok_with_tools
run_test_case "check-desk-static-site-runtime reports missing tools" test_static_runtime_reports_missing

finish_tests
