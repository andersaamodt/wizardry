#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - look prints usage
# - fails when read-magic is unavailable
# - reports missing attributes when no metadata exists
# - prints discovered attributes
# - writes rc block when ask_yn agrees

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

make_stub_dir() {
  dir=$(make_tempdir)
  cat >"$dir/ask_yn" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$dir/ask_yn"
  printf '%s\n' "$dir"
}

test_help() {
  run_spell "spells/look" --help
  assert_success && assert_output_contains "Usage: look"
}

test_missing_read_magic() {
  stub=$(make_stub_dir)
  PATH="$stub:/bin:/usr/bin" run_spell "spells/look" "$WIZARDRY_TMPDIR"
  assert_failure && assert_error_contains "look: read-magic spell is missing."
}

test_missing_attributes() {
  stub=$(make_stub_dir)
  cat >"$stub/read-magic" <<'EOF'
#!/bin/sh
printf '%s\n' 'Error: The attribute does not exist.'
EOF
  chmod +x "$stub/read-magic"
  PATH="$stub:/bin:/usr/bin" run_spell "spells/look" "$WIZARDRY_TMPDIR"
  assert_success && assert_output_contains "You look, but you don't see anything."
}

test_displays_attributes() {
  stub=$(make_stub_dir)
  cat >"$stub/read-magic" <<'EOF'
#!/bin/sh
case "$2" in
  name) printf '%s\n' 'Hidden Door' ;;
  description) printf '%s\n' 'A narrow doorway concealed by ivy.' ;;
esac
EOF
  chmod +x "$stub/read-magic"
  PATH="$stub:/bin:/usr/bin" run_spell "spells/look" "$WIZARDRY_TMPDIR"
  assert_success && printf '%s' "$OUTPUT" | grep -q "Hidden Door" && printf '%s' "$OUTPUT" | grep -q "A narrow doorway concealed by ivy."
}

test_installs_when_prompted() {
  stub=$(make_stub_dir)
  cat >"$stub/read-magic" <<'EOF'
#!/bin/sh
printf '%s\n' 'Error: The attribute does not exist.'
EOF
  chmod +x "$stub/read-magic"
  rc_file="$WIZARDRY_TMPDIR/lookrc"
  LOOK_RC_FILE="$rc_file" PATH="$stub:/bin:/usr/bin" run_spell "spells/look" "$WIZARDRY_TMPDIR"
  assert_success && assert_path_exists "$rc_file" && grep -q "wizardry look spell" "$rc_file"
}

run_test_case "look prints usage" test_help
run_test_case "look fails when read-magic is missing" test_missing_read_magic
run_test_case "look reports missing attributes" test_missing_attributes
run_test_case "look prints discovered attributes" test_displays_attributes
run_test_case "look installs rc block when approved" test_installs_when_prompted
finish_tests
