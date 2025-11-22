#!/bin/sh
# Behavioral coverage for memorize:
# - prints usage
# - fails when detect-rc-file helper is missing
# - installs eligible spells and exports detected environment
# - skips non-installable files during --all scans
# - records spellbook aliases
# - rejects aliases without a command

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

reset_logs() {
  rm -f "$WIZARDRY_TMPDIR/memorize.log" "$WIZARDRY_TMPDIR/spellbook.log"
}

create_detect_stub() {
  dir=$1
  stub="$dir/detect-rc-file"
  cat >"$stub" <<'SCRIPT'
#!/bin/sh
printf '%s\n' "platform=test-os"
printf '%s\n' "rc_file=/tmp/.wizardrc"
printf '%s\n' "format=ini"
SCRIPT
  chmod +x "$stub"
  printf '%s\n' "$stub"
}

create_installable_spell() {
  dir=$1
  spell="$dir/installable.sh"
  cat >"$spell" <<'SCRIPT'
#!/bin/sh
install() {
  printf '%s|%s|%s|%s\n' \
    "${WIZARDRY_PLATFORM-}" \
    "${WIZARDRY_RC_FILE-}" \
    "${WIZARDRY_RC_FORMAT-}" \
    "${WIZARDRY_MEMORIZE_TARGET-}" \
    >>"${WIZARDRY_TMPDIR}/memorize.log"
}
SCRIPT
  chmod +x "$spell"
  printf '%s\n' "$spell"
}

create_failing_spell() {
  dir=$1
  spell="$dir/failing.sh"
  cat >"$spell" <<'SCRIPT'
#!/bin/sh
install() {
  printf '%s\n' "called failing install" >>"${WIZARDRY_TMPDIR}/memorize.log"
  return 1
}
SCRIPT
  chmod +x "$spell"
  printf '%s\n' "$spell"
}

create_ask_stub() {
  dir=$1
  mode=$2
  stub="$dir/ask_yn"
  cat >"$stub" <<SCRIPT
#!/bin/sh
case "$mode" in
  yes) exit 0 ;;
  *) exit 1 ;;
esac
SCRIPT
  chmod +x "$stub"
  printf '%s\n' "$stub"
}

create_detect_stub_missing_rc() {
  dir=$1
  stub="$dir/detect-rc-file"
  cat >"$stub" <<'SCRIPT'
#!/bin/sh
printf '%s\n' "platform=test-os"
SCRIPT
  chmod +x "$stub"
  printf '%s\n' "$stub"
}

test_help() {
  reset_logs
  run_spell "spells/memorize" --help
  assert_success && assert_output_contains "Usage:"
}

test_missing_detect_helper_fails() {
  reset_logs
  case_dir=$(make_tempdir)
  spell=$(create_installable_spell "$case_dir")
  PATH=/usr/bin:/bin MEMORIZE_DETECT_RC_FILE="$case_dir/missing" \
    run_spell_in_dir "$case_dir" "spells/memorize" "$spell"
  assert_failure && assert_error_contains "detect-rc-file spell is missing"
}

test_installs_and_exports_environment() {
  reset_logs
  case_dir=$(make_tempdir)
  detect_stub=$(create_detect_stub "$case_dir")
  spell=$(create_installable_spell "$case_dir")

  MEMORIZE_DETECT_RC_FILE="$detect_stub" \
    run_spell_in_dir "$case_dir" "spells/memorize" "$spell"

  assert_success
  assert_output_contains "Memorized 1 spell(s); 0 skipped."
  assert_path_exists "$WIZARDRY_TMPDIR/memorize.log"
  contents=$(cat "$WIZARDRY_TMPDIR/memorize.log")
  case "$contents" in
    "test-os|/tmp/.wizardrc|ini|$spell") : ;; 
    *) TEST_FAILURE_REASON="unexpected environment record: $contents"; return 1 ;;
  esac
}

test_all_skips_non_installable() {
  reset_logs
  case_dir=$(make_tempdir)
  detect_stub=$(create_detect_stub "$case_dir")
  good=$(create_installable_spell "$case_dir")
  printf '%s\n' "echo not installable" >"$case_dir/plain.sh"
  chmod +x "$case_dir/plain.sh"

  MEMORIZE_DETECT_RC_FILE="$detect_stub" \
    run_spell_in_dir "$case_dir" "spells/memorize" --all "$case_dir"

  assert_success
  assert_output_contains "Memorized 1 spell(s); 1 skipped."
  contents=$(cat "$WIZARDRY_TMPDIR/memorize.log")
  case "$contents" in
    "test-os|/tmp/.wizardrc|ini|$good") : ;; 
    *) TEST_FAILURE_REASON="unexpected environment record for --all: $contents"; return 1 ;;
  esac
}

test_alias_records_command() {
  reset_logs
  case_dir=$(make_tempdir)
  store="$case_dir/spellbook-store"
  cat >"$store" <<'SCRIPT'
#!/bin/sh
printf '%s\n' "$*" >>"${WIZARDRY_TMPDIR}/spellbook.log"
SCRIPT
  chmod +x "$store"

  MEMORIZE_SPELLBOOK_STORE="$store" run_spell "spells/memorize" alias zap echo hello

  assert_success
  assert_output_contains "Spellbook memorized: zap -> echo hello"
  assert_path_exists "$WIZARDRY_TMPDIR/spellbook.log"
  recorded=$(cat "$WIZARDRY_TMPDIR/spellbook.log")
  case "$recorded" in
    "add zap echo hello") : ;;
    *) TEST_FAILURE_REASON="unexpected spellbook invocation: $recorded"; return 1 ;;
  esac
}

test_alias_requires_command() {
  run_spell "spells/memorize" alias onlyname
  assert_failure && assert_error_contains "alias requires a NAME and a COMMAND"
}

test_alias_fails_when_store_missing() {
  reset_logs
  missing="$(make_tempdir)/spellbook-store"
  PATH=/usr/bin:/bin MEMORIZE_SPELLBOOK_STORE="$missing" \
    run_spell "spells/memorize" alias zap echo hi
  assert_failure && assert_error_contains "spellbook-store helper is unavailable"
}

test_prompt_decline_exits_cleanly() {
  reset_logs
  case_dir=$(make_tempdir)
  ask_stub=$(create_ask_stub "$case_dir" no)
  MEMORIZE_ASK_YN="$ask_stub" run_spell_in_dir "$case_dir" "spells/memorize"
  assert_success && assert_output_contains "No spells memorized."
}

test_prompt_accept_scans_directory() {
  reset_logs
  case_dir=$(make_tempdir)
  ask_stub=$(create_ask_stub "$case_dir" yes)
  detect_stub=$(create_detect_stub "$case_dir")
  good=$(create_installable_spell "$case_dir")
  printf '%s\n' "echo skip" >"$case_dir/plain.sh"
  chmod +x "$case_dir/plain.sh"

  MEMORIZE_ASK_YN="$ask_stub" MEMORIZE_DETECT_RC_FILE="$detect_stub" \
    run_spell_in_dir "$case_dir" "spells/memorize"

  assert_success
  assert_output_contains "Memorized 1 spell(s); 1 skipped."
  contents=$(cat "$WIZARDRY_TMPDIR/memorize.log")
  case "$contents" in
    "test-os|/tmp/.wizardrc|ini|$good"|"test-os|/tmp/.wizardrc|ini|./installable.sh") : ;;
    *) TEST_FAILURE_REASON="prompted install produced: $contents"; return 1 ;;
  esac
}

test_recursive_requires_directory() {
  run_spell "spells/memorize" --recursive
  assert_failure && assert_error_contains "requires an explicit directory path"
}

test_install_failures_are_reported() {
  reset_logs
  case_dir=$(make_tempdir)
  detect_stub=$(create_detect_stub "$case_dir")
  failing=$(create_failing_spell "$case_dir")

  MEMORIZE_DETECT_RC_FILE="$detect_stub" run_spell "spells/memorize" "$failing"

  assert_success
  assert_output_contains "Installation failed for '$failing'."
  assert_output_contains "Memorized 0 spell(s); 1 skipped."
  assert_path_exists "$WIZARDRY_TMPDIR/memorize.log"
  assert_file_contains "$WIZARDRY_TMPDIR/memorize.log" "called failing install"
}

test_detect_stub_without_rc_fails() {
  reset_logs
  case_dir=$(make_tempdir)
  detect_stub=$(create_detect_stub_missing_rc "$case_dir")
  spell=$(create_installable_spell "$case_dir")

  MEMORIZE_DETECT_RC_FILE="$detect_stub" run_spell "spells/memorize" "$spell"

  assert_failure && assert_error_contains "did not yield an rc file"
}

run_test_case "memorize prints usage" test_help
run_test_case "memorize fails without detect-rc-file" test_missing_detect_helper_fails
run_test_case "memorize installs and exports environment" test_installs_and_exports_environment
run_test_case "memorize --all skips non-installable entries" test_all_skips_non_installable
run_test_case "memorize records spellbook aliases" test_alias_records_command
run_test_case "memorize rejects empty alias commands" test_alias_requires_command
run_test_case "memorize fails when spellbook-store is missing" test_alias_fails_when_store_missing
run_test_case "memorize declines prompts cleanly" test_prompt_decline_exits_cleanly
run_test_case "memorize prompt yes scans directory" test_prompt_accept_scans_directory
run_test_case "memorize --recursive requires a directory" test_recursive_requires_directory
run_test_case "memorize reports failed installs" test_install_failures_are_reported
run_test_case "memorize fails when detect-rc-file omits rc" test_detect_stub_without_rc_fails
finish_tests
