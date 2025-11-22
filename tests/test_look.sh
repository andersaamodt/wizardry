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
  cat >"$stub/ask_yn" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub/ask_yn"
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
  cat >"$stub/ask_yn" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub/ask_yn"
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
  cat >"$stub/ask_yn" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub/ask_yn"
  cat >"$stub/read-magic" <<'EOF'
#!/bin/sh
printf '%s\n' 'Error: The attribute does not exist.'
EOF
  chmod +x "$stub/read-magic"
  rc_file="$WIZARDRY_TMPDIR/lookrc-install"
  LOOK_RC_FILE="$rc_file" PATH="$stub:/bin:/usr/bin" run_spell "spells/look" "$WIZARDRY_TMPDIR"
  assert_success && assert_path_exists "$rc_file" && grep -q "wizardry look spell" "$rc_file"
}

test_declines_installation() {
  stub=$(make_stub_dir)
  cat >"$stub/ask_yn" <<'EOF'
#!/bin/sh
echo "$1" >"$ASK_LOG"
exit 1
EOF
  chmod +x "$stub/ask_yn"
  cat >"$stub/read-magic" <<'EOF'
#!/bin/sh
printf '%s\n' 'Error: The attribute does not exist.'
EOF
  chmod +x "$stub/read-magic"
  rc_file="$WIZARDRY_TMPDIR/lookrc-decline"
  rm -f "$rc_file"
  prompt_log="$WIZARDRY_TMPDIR/prompt.txt"
  ASK_LOG="$prompt_log" LOOK_RC_FILE="$rc_file" PATH="$stub:/bin:/usr/bin" run_spell "spells/look" "$WIZARDRY_TMPDIR"
  assert_success && assert_path_missing "$rc_file" && assert_output_contains "The mud will only run in this shell window." &&
    assert_file_contains "$prompt_log" "Memorize the 'look' spell so it is always available?"
}

test_skips_install_when_block_present() {
  stub=$(make_stub_dir)
  cat >"$stub/ask_yn" <<'EOF'
#!/bin/sh
echo "ask_yn should not be called" >&2
exit 9
EOF
  chmod +x "$stub/ask_yn"
  cat >"$stub/read-magic" <<'EOF'
#!/bin/sh
printf '%s\n' 'Error: The attribute does not exist.'
EOF
  chmod +x "$stub/read-magic"
  rc_file="$WIZARDRY_TMPDIR/lookrc-preexisting"
  cat >"$rc_file" <<'EOF'
# >>> wizardry look spell >>>
alias look='/existing/look/path'
# <<< wizardry look spell <<<
EOF
  before=$(cat "$rc_file")
  LOOK_RC_FILE="$rc_file" PATH="$stub:/bin:/usr/bin" run_spell "spells/look" "$WIZARDRY_TMPDIR"
  assert_success && assert_file_contains "$rc_file" "wizardry look spell" && [ "$(cat "$rc_file")" = "$before" ]
}

run_test_case "look prints usage" test_help
run_test_case "look fails when read-magic is missing" test_missing_read_magic
run_test_case "look reports missing attributes" test_missing_attributes
run_test_case "look prints discovered attributes" test_displays_attributes
run_test_case "look installs rc block when approved" test_installs_when_prompted
run_test_case "look declines installation when user says no" test_declines_installation
run_test_case "look skips installation when rc block already exists" test_skips_install_when_block_present
finish_tests
