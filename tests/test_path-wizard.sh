#!/bin/sh
# Behavioral cases (derived from --help):
# - path-wizard prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/path-wizard" --help
  assert_success && assert_error_contains "Usage: path-wizard"
}

test_missing_detect_helper() {
  DETECT_RC_FILE="$WIZARDRY_TMPDIR/missing-detect" run_spell "spells/path-wizard" --rc-file "$WIZARDRY_TMPDIR/rc" --format shell add 2>/dev/null
  assert_failure && assert_error_contains "required helper"
}

test_unknown_option() {
  run_spell "spells/path-wizard" --unknown
  assert_failure && assert_error_contains "unknown option"
}

test_adds_shell_path_entry() {
  rc="$WIZARDRY_TMPDIR/path_rc"
  detect_stub="$WIZARDRY_TMPDIR/detect-rc-file"
  cat >"$detect_stub" <<'EOF'
#!/bin/sh
printf 'platform=debian\nrc_file=%s\nformat=shell\n' "$WIZARDRY_TMPDIR/path_rc"
EOF
  chmod +x "$detect_stub"

  run_spell "spells/path-wizard" --rc-file "$rc" --format shell --platform debian add "$WIZARDRY_TMPDIR"
  assert_success
  assert_file_contains "$rc" "wizardry: path-"
  assert_file_contains "$rc" "export PATH=\"$WIZARDRY_TMPDIR:\$PATH\""
}

test_status_requires_directory() {
  run_spell "spells/path-wizard" status
  assert_failure && assert_error_contains "expects a directory argument"
}

run_test_case "path-wizard prints usage" test_help
run_test_case "path-wizard fails when detect helper missing" test_missing_detect_helper
run_test_case "path-wizard rejects unknown options" test_unknown_option
run_test_case "path-wizard adds shell PATH entries" test_adds_shell_path_entry
run_test_case "path-wizard status without directory fails" test_status_requires_directory
finish_tests
