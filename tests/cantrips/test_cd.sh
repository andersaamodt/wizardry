#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - cd installs rc hook when user agrees
# - cd skips installation and still casts look after successful directory change
# - cd --install works in silent mode
# - cd --install detects already installed hooks
# - cd uses detect-rc-file for cross-platform support
# - cd shows random narration when enabled
# - cd handles missing HOME gracefully
# - cd handles missing detect-rc-file gracefully

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

test_cd_installs_hook_when_user_agrees() {
  tmp=$(make_tempdir)
  cat >"$tmp/ask_yn" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/ask_yn"

  run_cmd env PATH="$tmp:$PATH" WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/cantrips/cd" "$tmp"
  assert_success && assert_path_exists "$tmp/rc" && assert_output_contains "installed wizardry hooks"
}

test_cd_casts_look_after_directory_change() {
  tmp=$(make_tempdir)
  cat >"$tmp/ask_yn" <<'SH'
#!/bin/sh
exit 1
SH
  chmod +x "$tmp/ask_yn"
  cat >"$tmp/look" <<'SH'
#!/bin/sh
printf 'looked' > "$PWD/looked"
SH
  chmod +x "$tmp/look"

  target="$WIZARDRY_TMPDIR/room"
  mkdir -p "$target"

  run_cmd env PATH="$tmp:$PATH" WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/cantrips/cd" "$target"
  assert_success && assert_path_exists "$target/looked"
}

test_cd_install_silent() {
  tmp=$(make_tempdir)
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/cantrips/cd" --install --silent
  assert_success && assert_path_exists "$tmp/rc" && assert_output_contains "installed wizardry hooks"
}

test_cd_install_already_present() {
  tmp=$(make_tempdir)
  cat >"$tmp/rc" <<'RC'
# >>> wizardry cd cantrip >>>
WIZARDRY_CD_CANTRIP='/some/path/cd'
WIZARDRY_CD_NARRATION=1
alias cd='. "$WIZARDRY_CD_CANTRIP"'
# <<< wizardry cd cantrip <<<
RC

  cat >"$tmp/ask_yn" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/ask_yn"

  run_cmd env PATH="$tmp:$PATH" WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/cantrips/cd" --install
  assert_success && assert_output_contains "already installed"
}

test_cd_uses_detect_rc_file() {
  tmp=$(make_tempdir)
  cat >"$tmp/detect-rc-file" <<SH
#!/bin/sh
printf 'platform=debian\n'
printf 'rc_file=$tmp/custom_rc\n'
printf 'format=shell\n'
SH
  chmod +x "$tmp/detect-rc-file"

  run_cmd env PATH="$tmp:$PATH" HOME="$tmp" "$ROOT_DIR/spells/cantrips/cd" --install --silent
  assert_success && assert_path_exists "$tmp/custom_rc"
}

test_cd_shows_narration() {
  tmp=$(make_tempdir)
  cat >"$tmp/ask_yn" <<'SH'
#!/bin/sh
exit 1
SH
  chmod +x "$tmp/ask_yn"
  cat >"$tmp/look" <<'SH'
#!/bin/sh
:
SH
  chmod +x "$tmp/look"

  target="$WIZARDRY_TMPDIR/narration_room"
  mkdir -p "$target"

  run_cmd env PATH="$tmp:$PATH" WIZARDRY_RC_FILE="$tmp/rc" WIZARDRY_CD_NARRATION=1 "$ROOT_DIR/spells/cantrips/cd" "$target"
  # Check if output contains any of the narration keywords
  assert_success
  case "$OUTPUT" in
    *teleport*|*shimmer*|*breeze*|*energies*|*path*|*traverse*|*runes*|*translocation*|*phase*|*swirl*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="output missing narration message"
      return 1
      ;;
  esac
}

test_cd_missing_home() {
  tmp=$(make_tempdir)
  run_cmd env -u HOME WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/cantrips/cd" --install --silent
  assert_success
}

test_cd_hook_includes_narration() {
  tmp=$(make_tempdir)
  run_cmd env WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/cantrips/cd" --install --silent
  assert_success && assert_file_contains "$tmp/rc" "WIZARDRY_CD_NARRATION=1"
}

test_cd_help() {
  run_cmd "$ROOT_DIR/spells/cantrips/cd" --help
  assert_success && assert_output_contains "Usage:" && assert_output_contains "--install"
}

test_cd_handles_invalid_directory() {
  tmp=$(make_tempdir)
  cat >"$tmp/ask_yn" <<'SH'
#!/bin/sh
exit 1
SH
  chmod +x "$tmp/ask_yn"

  run_cmd env PATH="$tmp:$PATH" WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/cantrips/cd" "/nonexistent/directory/path"
  # cd command prints error to stderr but wizardry continues, checking for error message
  assert_error_contains "can't cd to"
}

test_cd_narration_disabled_by_default_without_hook() {
  tmp=$(make_tempdir)
  cat >"$tmp/ask_yn" <<'SH'
#!/bin/sh
exit 1
SH
  chmod +x "$tmp/ask_yn"
  cat >"$tmp/look" <<'SH'
#!/bin/sh
:
SH
  chmod +x "$tmp/look"

  target="$WIZARDRY_TMPDIR/no_narration_room"
  mkdir -p "$target"

  # Without WIZARDRY_CD_NARRATION=1, narration should not appear
  run_cmd env PATH="$tmp:$PATH" WIZARDRY_RC_FILE="$tmp/rc" "$ROOT_DIR/spells/cantrips/cd" "$target"
  assert_success
  case "$OUTPUT" in
    *teleport*|*shimmer*|*breeze*|*energies*|*path*|*traverse*|*runes*|*translocation*|*phase*|*swirl*)
      TEST_FAILURE_REASON="narration appeared when it should be disabled"
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

run_test_case "cd installs rc hook when user agrees" test_cd_installs_hook_when_user_agrees
run_test_case "cd skips installation and casts look after directory change" test_cd_casts_look_after_directory_change
run_test_case "cd --install works in silent mode" test_cd_install_silent
run_test_case "cd --install detects already installed hooks" test_cd_install_already_present
run_test_case "cd uses detect-rc-file for cross-platform support" test_cd_uses_detect_rc_file
run_test_case "cd shows random narration when enabled" test_cd_shows_narration
run_test_case "cd handles missing HOME gracefully" test_cd_missing_home
run_test_case "cd hook includes WIZARDRY_CD_NARRATION" test_cd_hook_includes_narration
run_test_case "cd --help shows usage" test_cd_help
run_test_case "cd handles invalid directory" test_cd_handles_invalid_directory
run_test_case "cd narration disabled without WIZARDRY_CD_NARRATION" test_cd_narration_disabled_by_default_without_hook
finish_tests
