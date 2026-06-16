#!/bin/sh
# Test detect-xattr-capability imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/.imps/sys/detect-xattr-capability --help
  assert_success || return 1
  assert_output_contains "Usage: detect-xattr-capability" || return 1
  assert_output_contains "filesystem-unsupported" || return 1
}

test_reports_filesystem_unsupported_when_helper_probe_fails() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"

  cat >"$stub_dir/attr" <<'SH'
#!/bin/sh
exit 1
SH
  chmod +x "$stub_dir/attr"

  run_cmd env PATH="$stub_dir:$PATH" "$ROOT_DIR/spells/.imps/sys/detect-xattr-capability"
  assert_success || return 1
  assert_output_contains "filesystem-unsupported" || return 1
}

test_reports_supported_when_helper_probe_succeeds() {
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"

  cat >"$stub_dir/attr" <<'SH'
#!/bin/sh
case "${1-}" in
  -s|-r)
    exit 0
    ;;
esac
exit 1
SH
  chmod +x "$stub_dir/attr"

  run_cmd env PATH="$stub_dir:$PATH" "$ROOT_DIR/spells/.imps/sys/detect-xattr-capability"
  assert_success || return 1
  assert_output_contains "supported" || return 1
}

run_test_case "detect-xattr-capability shows help" test_help
run_test_case "detect-xattr-capability reports unsupported filesystems" \
  test_reports_filesystem_unsupported_when_helper_probe_fails
run_test_case "detect-xattr-capability reports supported filesystems" \
  test_reports_supported_when_helper_probe_succeeds

finish_tests
